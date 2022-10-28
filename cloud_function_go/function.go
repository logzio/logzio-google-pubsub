// Package p contains an HTTP Cloud Function.
package p

import (
	"encoding/base64"
	"encoding/json"
	"fmt"
	"net/http"
	"os"

	"github.com/logzio/logzio-go"
)

func LogzioHandler(w http.ResponseWriter, r *http.Request) {
	var d struct {
		Message string `json:"data"`
	}
	token := r.URL.Query().Get("token")
	typeLog := r.URL.Query().Get("type")
	listener := r.URL.Query().Get("listener")
	url := fmt.Sprintf("https://%s:8071", listener)
	tokenAddType := fmt.Sprintf("%s&type=%s", token, typeLog)
	err := json.NewDecoder(r.Body).Decode(&d)
	if err != nil {
		fmt.Println(err)
		panic(err)
	}

	rawDecodedText, err := base64.StdEncoding.DecodeString(d.Message)

	l, err := logzio.New(
		tokenAddType,
		logzio.SetDebug(os.Stderr),
		logzio.SetUrl(url),
		logzio.SetInMemoryQueue(true),
		logzio.SetinMemoryCapacity(24000000),
		logzio.SetlogCountLimit(6000000),
	) // token is required
	if err != nil {
		panic(err)
	}
	err = l.Send([]byte(rawDecodedText))
	if err != nil {
		panic(err)
	}

	l.Stop()
}
