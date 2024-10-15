# Lazarus Integration with ChatGPT

This project demonstrates how to integrate the ChatGPT API into a Lazarus application. Below, you'll find a script example showing how to use the `TCHATGPT` class to send questions and receive responses from ChatGPT.

## How to use the class

```pascal
uses ..., chatgpt;

var
  FChatgpt: TCHATGPT;
  Response: string;

begin
  FChatgpt := TChatgpt.Create(Self);
  try
    FChatgpt.TOKEN := 'YOUR_TOKEN'; // Add your OpenAI API token
    FChatgpt.SendQuestion('Your Question');
    Response := FChatgpt.Response;  // Retrieves the response from ChatGPT
    ShowMessage('ChatGPT Response: ' + Response); // Display the response in a message dialog
  finally
    FChatgpt.Free; // Free memory after use
  end;
end.
```

# How it works
FChatgpt: This is an instance of the TCHATGPT class, which is responsible for communicating with the ChatGPT API.
TOKEN: Set your OpenAI API token here to authenticate the requests.
SendQuestion: This method sends your question to the API and processes the response.
Response: The result returned by the API, which can be displayed or used further in your program.
Library Requirements
To ensure proper functionality, you need to copy the libraries provided in the demo folder to the following system directory:



C:/Windows/System32
This step is necessary to ensure that all required dependencies for the TCHATGPT class and API communication are properly available.

# Demo Program
A complete demo program is available in the ./demo folder. You can run this demo to see how the TCHATGPT class works in a real application.

It also contains the required libraries for the project, which need to be copied to C:/Windows/System32 as described in the Library Requirements section.
