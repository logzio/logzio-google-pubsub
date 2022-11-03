// Package p contains an HTTP Cloud Function.
package p

import (
	"bytes"
	"compress/gzip"
	"encoding/base64"
	"encoding/binary"
	"encoding/json"
	"fmt"
	"net/http"
	"time"
)

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
		fmt.Printf("Got HTTP %d unauthorized, skip retry\n", statusCode)
		retry = false
	case http.StatusForbidden:
		fmt.Printf("Got HTTP %d forbidden, skip retry\n", statusCode)
		retry = false
	case http.StatusOK:
		retry = false
	}
	return retry
}

func validateArguments(r *http.Request) bool {
	validateCheck := true

	token := r.URL.Query().Get("token")
	if len(token) == 0 {
		fmt.Printf("Logzio token must be provided")
		validateCheck = false
	}

	listener := r.URL.Query().Get("listener")
	if len(listener) == 0 {
		fmt.Printf("Logzio listener must be provided")
		validateCheck = false
	}

	typeLog := r.URL.Query().Get("type")
	if len(typeLog) == 0 {
		fmt.Printf("Set default log type, `pubsub`")
		typeLog = "pubsub"
	}

	return validateCheck
}

func urlBuilder(r *http.Request) string {
	token := r.URL.Query().Get("token")
	listener := r.URL.Query().Get("listener")
	typeLog := r.URL.Query().Get("type")

	return fmt.Sprintf("https://%s:8071/?token=%s&type=%s", listener, token, typeLog)
}

func doRequest(rawDecodedText []byte, url string) {
	// gzip compress data before shipping
	var compressedBuf bytes.Buffer
	gzipWriter := gzip.NewWriter(&compressedBuf)
	_, err := gzipWriter.Write(rawDecodedText)
	if err != nil {
		fmt.Printf("Failed to compress log")
		return
	}
	err = gzipWriter.Close()
	if err != nil {
		fmt.Printf("Failed to close gzip")
		return
	}
	if binary.Size(compressedBuf) > 10485760 {
		fmt.Printf("The request body size is larger than 10 MB. Failed to send log")
		return
	}

	backOff := time.Second * 2
	sendRetries := 4
	toBackOff := false
	for attempt := 0; attempt < sendRetries; attempt++ {
		if toBackOff {
			fmt.Printf("Failed to send logs, trying again in %v\n", backOff)
			time.Sleep(backOff)
			backOff *= 2
		}
		resp, err := http.Post(url, "application/json",
			bytes.NewBuffer(rawDecodedText))
		if err != nil {
			fmt.Printf("Can't send data to logz.io, reason is: %w", err)
			return
		}
		if shouldRetry(resp.StatusCode) {
			toBackOff = true
		} else {
			break
		}
	}
}

func LogzioHandler(w http.ResponseWriter, r *http.Request) {
	type Data struct {
		Data string `json:"data"`
	}

	var d struct {
		Message Data `json:"message"`
	}

	if validateArguments(r) {

		url := urlBuilder(r)
		err := json.NewDecoder(r.Body).Decode(&d)
		if err != nil {
			fmt.Printf("Can't decode request's body with log message: %w", err)
			return
		}

		rawDecodedText, err := base64.StdEncoding.DecodeString(d.Message.Data)
		if err != nil {
			fmt.Printf("Message log can't be parsed: %w", err)
			return
		}

		doRequest(rawDecodedText, url)
	}

}
