// Package p contains an HTTP Cloud Function.
package p

import (
	"encoding/base64"
	"encoding/json"
	"fmt"
	"net/http"

	"github.com/logzio/logzio-go"
)

func LogzioHandler(w http.ResponseWriter, r *http.Request) {
	type Data struct {
		Data string `json:"data"`
	}

	var d struct {
		Message Data `json:"message"`
	}
	token := r.URL.Query().Get("token")
	typeLog := r.URL.Query().Get("type")
	listener := r.URL.Query().Get("listener")
	url := fmt.Sprintf("https://%s:8071", listener)
	tokenAddType := fmt.Sprintf("%s&type=%s", token, typeLog)
	err := json.NewDecoder(r.Body).Decode(&d)
	if err != nil {
		return nil, fmt.Errorf("Can't decode request's body with log message: %w", err)
	}

	rawDecodedText, err := base64.StdEncoding.DecodeString(d.Message.Data)
	if err != nil {
		return nil, fmt.Errorf("Message log can't be parsed: %w", err)
	}

	l, err := logzio.New(tokenAddType, logzio.SetUrl(url)) // token is required
	if err != nil {
		return nil, fmt.Errorf("Logz.io connection failed: %w", err)
	}
	err = l.Send([]byte(rawDecodedText))
	if err != nil {
		return nil, fmt.Errorf("Can't send log data to logz.io: %w", err)
	}
	l.Stop()
	return
}
