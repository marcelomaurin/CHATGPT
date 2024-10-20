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

# Important Notice
In order for this program to work, you need to have an active subscription to the paid API of ChatGPT. Ensure that you have sufficient credits in your OpenAI account, as this service is not available for free. You can set up billing and manage your API usage at the OpenAI platform.

# Installing the TCHATGPT Package in Lazarus
To install the TCHATGPT component from the provided package in the pacote subfolder, follow these steps:

## Open the Package:

In the Lazarus IDE, go to Package > Open Package File (.lpk).
Navigate to the pacote folder and select the chatgpt.lpk package file.
Compile the package:

Once the package is open, click on Compile to compile the package and ensure there are no errors.
Install the package:

After compiling successfully, click Use > Install. Lazarus will ask to rebuild the IDE and restart.
After restarting, the TCHATGPT component will be available under the OpenAI tab in the component palette.
Using the Component:

Once installed, you can drag and drop the TCHATGPT component onto your form in Lazarus and set the properties such as TOKEN, Question, and Response through the Object Inspector or programmatically in your code.
