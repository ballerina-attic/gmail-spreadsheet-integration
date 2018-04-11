# Reading Google Sheet and Messaging with GMail

Google Sheets is an online spreadsheet that lets users create and format spreadsheets and simultaneously work with other 
people. Gmail is a free, Web-based e-mail service provided by Google.

> This guide walks you through the process of using Google Sheets and GMail using Ballerina language.

The following are the sections available in this guide.

- [What you'll build](#what-you-build)
- [Prerequisites](#pre-req)
- [Developing the application](#developing-service)
- [Testing](#testing)

## <a name="what-you-build"></a>  What you’ll build

To understand how you can use Ballerina API Connectors,  in this sample we use GMail connector and Spreadsheet connector. Let us consider a real world use case scenario of a software product company. When a customer downloads the product from the company website, providing the name and email address, the company sends a customized email to the customer’s mailbox saying,

                                                             Hi <CustomerName>,
                                                    Thank you for downloading the product !
  

The customer names are added to the first column and their email addresses are added to the second column of a Google Spreadsheet.

You can use the Ballerina Spreadsheet connector to read the spreadsheet, iterate through the rows and picking up the email address and name of each customer from the columns. Then you can use the GMail connector to simply add the name to the body of some standard-html-mail template and send the email to the relevant customer.

## <a name="pre-req"></a> Prerequisites
 
- JDK 1.8 or later
- [Ballerina Distribution](https://ballerinalang.org/docs/quick-tour/quick-tour/#install-ballerina) 
- A Text Editor or an IDE
- Obtain following information and credentials for both Google Sheets and GMail APIs. 
    * Base URl (https://www.googleapis.com/gmail)
    * Client Id
    * Client Secret
    * Access Token
    * Refresh Token
    * Refresh Token Endpoint (https://www.googleapis.com)
    * Refresh Token Path (/oauth2/v3/token)

Optional requirements
- Ballerina IDE plugins (IntelliJ IDEA, VSCode, Atom)

## <a name="develop-app"></a> Developing the application
### <a name="before-begin"></a> Before you begin
##### Understand the package structure

Ballerina is a complete programming language that can have any custom project structure as you wish. Although language allows you to have any package structure, we'll stick with the following package structure for this project.

```
integrating-googlesheet-gmail
  ├── ballerina.conf  
  └── src
      └── Application
          ├── spreadsheet_manager.bal
          ├── gmail_manager.bal
          ├── application.bal
          └── test
              └── spreadsheet_manager.bal
              └── gmail_manager.bal  
```

##### Change the authorization configurations in the `ballerina.conf` file

You will need to have a Google account and configure the `ballerina.conf` configuration
file with the obtained tokens as follows.

###### ballerina.conf
```ballerina.conf
SHEETS_BASEURL="enter the base url for google sheets api"
GMAIL_BASEURL="enter the base url for gmail api"
ACCESS_TOKEN="enter your access token here"
CLIENT_ID="enter your client id here"
CLIENT_SECRET="enter your client secret here"
REFRESH_TOKEN="enter your refresh token here"
REFRESH_TOKEN_ENDPOINT="enter your refresh token endpoint here"
REFRESH_TOKEN_PATH="enter your refresh token path here"
```
Make sure to edit these configurations with your personal google api credentials.

### <a name="Implementation"></a> Implementation

## <a name="testing"></a> Testing 

### <a name="try-out"></a> Try it out

Run this sample by entering the following command in a terminal,

```bash
<SAMPLE_ROOT_DIRECTORY>/src$ ballerina run Application/
```

#### <a name="response"></a> Response you'll get

Let's now look at some important log statements we will get as the response for this scenario.


### <a name="unit-testing"></a> Writing unit tests 
In ballerina, the unit test cases should be in the same package and the naming convention should be as follows,
In Ballerina, the unit test cases should be in the same package inside a folder named as 'test'.  When writing the test functions the below convention should be followed.
* Test functions should be annotated with `@test:Config`. See the below example.
  ```ballerina
    @test:Config
    function testCreateHtmlMessage() {
  ```

This guide contains unit test cases for each method implemented in `gmail_manager.bal` file.

To run the unit tests, go to the sample src directory and run the following command,

```bash
$ <SAMPLE_ROOT_DIRECTORY>/src$ ballerina test
```
