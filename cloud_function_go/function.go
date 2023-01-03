// Package p contains an HTTP Cloud Function.
package p

import (
	"bytes"
	"compress/gzip"
	"context"
	"encoding/binary"
	"encoding/json"
	"fmt"
	"net/http"
	"os"
	"time"
)

const maxSize = 512000

type logzioConfig struct {
	token      string
	listener   string
	typeLog    string
	validation bool
}
type PubSubMessage struct {
	Data []byte `json:"data"`
}

const textPayload = "textPayload"
const severity = "severity"

// client is used to make HTTP requests with a 10 second timeout.
// http.Clients should be reused instead of created as needed.
var client = &http.Client{
	Timeout: 10 * time.Second,
}

func shouldRetry(statusCode int) bool {
	retry := true
	switch statusCode {
	case http.StatusBadRequest:
		fmt.Printf("Got HTTP %d bad request, skip retry\n", statusCode)
		retry = false
	case http.StatusNotFound:
		fmt.Printf("Got HTTP %d not found, skip retry\n", statusCode)
		retry = false
	case http.StatusUnauthorized:
		fmt.Printf("Got HTTP %d unauthorized, skip retry.Please check your Logs' Token and try again\n", statusCode)
		retry = false
	case http.StatusForbidden:
		fmt.Printf("Got HTTP %d forbidden, skip retry\n", statusCode)
		retry = false
	case http.StatusOK:
		retry = false
	}
	return retry
}

func (l *logzioConfig) validateAndPopulateArguments() {

	token := os.Getenv("token")
	if len(token) == 0 {
		fmt.Printf("Logzio token must be provided")
		l.validation = false
	} else {
		l.token = token
	}

	listener := os.Getenv("listener")
	if len(listener) == 0 {
		fmt.Printf("Logzio listener must be provided")
		l.validation = false
	} else {
		l.listener = listener
	}

	typeLog := os.Getenv("type")
	if len(typeLog) == 0 {
		fmt.Printf("Set default log type, `pubsub`")
		l.typeLog = "pubsub"
	} else {
		l.typeLog = typeLog
	}

}

func updateFields(rawDecodedText *[]byte) error {
	var m map[string]interface{}
	err := json.Unmarshal(*rawDecodedText, &m)
	if err != nil {
		fmt.Printf("Can't parse a json: %s", err)
		return err
	}
	val, ok := m[textPayload]
	// If the key textPayload exists
	if ok {
		delete(m, textPayload)
		m["message"] = val
	}
	value, okey := m[severity]
	// If the key severity exists
	if okey {
		delete(m, severity)
		m["log_level"] = value
	}

	*rawDecodedText, err = json.Marshal(m)
	if err != nil {
		fmt.Printf("Can't parse to bytes: %s", err)
		return err
	}
	return nil
}

func doRequest(rawDecodedText []byte, url string) {

	err := updateFields(&rawDecodedText)
	if err != nil {
		fmt.Printf("Can't to parse json object: %s", err)
		return
	}
	if binary.Size(rawDecodedText) > maxSize {
		fmt.Printf("The request body size is larger than %d KB.", maxSize)
		cutMessage := string(rawDecodedText)[:maxSize]
		logToSend := fmt.Sprintf("{message:%s}", cutMessage)
		rawDecodedText = []byte(logToSend)
	}
	// gzip compress data before shipping
	var compressedBuf bytes.Buffer
	gzipWriter := gzip.NewWriter(&compressedBuf)
	gzipWriter.Write(rawDecodedText)
	gzipWriter.Close()

	backOff := time.Second * 2
	sendRetries := 4
	toBackOff := false
	for attempt := 0; attempt < sendRetries; attempt++ {
		if toBackOff {
			fmt.Printf("Failed to send logs, trying again in %s\n", backOff)
			time.Sleep(backOff)
			backOff *= 2
		}

		req, err := http.NewRequest("POST", url, &compressedBuf)
		if err != nil {
			fmt.Printf("Connection was failed: %s", err)
			return
		}
		req.Header.Add("Content-Encoding", "gzip")
		req.Header.Add("Content-Type", "text/plain")
		req.Header.Add("logzio-shipper", "logzio-go/v1.0.0")

		resp, err := client.Do(req)
		if err != nil {
			fmt.Printf("Can't send data to logz.io, reason is: %s", err)
			return
		}

		defer resp.Body.Close()

		if shouldRetry(resp.StatusCode) {
			toBackOff = true
		} else {
			break
		}

	}

}

func LogzioHandler(ctx context.Context, m PubSubMessage) error {

	logzioConfig := logzioConfig{}
	logzioConfig.validation = true
	logzioConfig.validateAndPopulateArguments()

	if logzioConfig.validation {
		url := fmt.Sprintf("https://%s:8071?token=%s&type=%s", logzioConfig.listener, logzioConfig.token, logzioConfig.typeLog)
		doRequest(m.Data, url)
		return nil
	}
	return nil
}
