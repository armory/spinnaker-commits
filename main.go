package main

import (
	"encoding/csv"
	"fmt"
	"html/template"
	"log"
	"net/http"
	"os"
	"time"
)

//Create a struct that holds information to be displayed in our HTML file
type Welcome struct {
	Name     string
	Time     string
	Data     [][]string
	Hostname string
}

//Go application entrypoint
func main() {
	//We tell Go exactly where we can find our html file. We ask Go to parse the html file (Notice
	// the relative path). We wrap it in a call to template.Must() which handles any errors and halts if there are fatal errors

	templates := template.Must(template.ParseFiles("templates/welcome.html"))

	//Our HTML comes with CSS that go needs to provide when we run the app. Here we tell go to create
	// a handle that looks in the static directory, go then uses the "/static/" as a url that our
	//html can refer to when looking for our css and other files.

	http.Handle("/static/", //final url can be anything
		http.StripPrefix("/static/",
			http.FileServer(http.Dir("static")))) //Go looks in the relative "static" directory first using http.FileServer(), then matches it to a
	//url of our choice as shown in http.Handle("/static/"). This url is what we need when referencing our css files
	//once the server begins. Our html code would therefore be <link rel="stylesheet"  href="/static/stylesheet/...">
	//It is important to note the url in http.Handle can be whatever we like, so long as we are consistent.

	//This method takes in the URL path "/" and a function that takes in a response writer, and a http request.
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		d, err := LoadData()

		if err != nil {
			fmt.Println("Error: Error loading data: " + err.Error())
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		// LOOK HERE!!!
		// Uncomment out the line when you want to sort the contents
		// Comment it to return it to default state
		BubbleSort(d)

		//Instantiate a Welcome struct object and pass in some random information.
		//We shall get the name of the user as a query parameter from the URL

		hostname, _ := os.Hostname()
		welcome := Welcome{
			"Anonymous",
			time.Now().Format(time.Stamp),
			d[:20],
			hostname,
		}
		//Takes the name from the URL query e.g ?name=Martin, will set welcome.Name = Martin.
		if name := r.FormValue("name"); name != "" {
			welcome.Name = name
		}
		//If errors show an internal server error message
		//I also pass the welcome struct to the welcome-template.html file.
		if err := templates.ExecuteTemplate(w, "welcome.html", welcome); err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
		}
	})

	//Start the web server, set the port to listen to 8080. Without a path it assumes localhost
	//Print any errors from starting the webserver using fmt
	fmt.Println("Listening")
	fmt.Println(http.ListenAndServe(":8080", nil))
}

func BubbleSort(items [][]string) {
	L := len(items)
	for i := 0; i < L; i++ {
		for j := 0; j < (L - 1 - i); j++ {
			if items[j][1] > items[j+1][1] {
				items[j], items[j+1] = items[j+1], items[j]
			}
		}
	}
}

func LoadData() (rec [][]string, err error) {
	r, err := os.Open("data/commits.csv")
	defer r.Close()
	if err != nil {
		log.Printf("Error: %s", err.Error())
		return nil, err
	}

	cr := csv.NewReader(r)

	records, err := cr.ReadAll()
	if err != nil {
		log.Printf("Error: %s", err.Error())
		return nil, err
	}

	log.Print(len(records))
	return records, nil
}
