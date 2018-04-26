# Gmail-Google Sheets Integration

[Google Sheets](https://www.google.com/sheets/about/) is an online spreadsheet that lets users create and format 
spreadsheets and simultaneously work with other people. [Gmail](https://www.google.com/gmail/) is a free, web-based 
e-mail service provided by Google.

> This guide walks you through the process of using Google Sheets and Gmail using Ballerina language.

The following are the sections available in this guide.

- [What you'll build](#what-youll-build)
- [Prerequisites](#pre-req)
- [Developing the application](#develop-prog)
- [Testing](#testing)
- [Deployment](#deployment)

## What you’ll build

To understand how you can use Ballerina API connectors, in this sample we use Spreadsheet connector to get 
data from a Google Sheet and send those data in an email using Gmail connector. 

Let us consider a real world use case scenario of a software product company. When a customer downloads the 
product from the company website, providing the name and email address, the company sends a customized email to the 
customer’s mailbox saying,

```
    Hi <CustomerName>
    
    Thank you for downloading the product <ProductName>!

    If you still have questions regarding <ProductName>, please contact us and we will get in touch with you right away!                                        
```
The product name, customer name and email address are added to the first, second and third columns of a Google Sheet.

![Gmail-Spreadsheet Integration Overview](images/gmail_spreadsheet_integration.svg)

You can use the Ballerina Google Spreadsheet connector to read the spreadsheet, iterate through the rows and pick 
up the product name, email address and name of each customer from the columns. Then, you can use the Gmail connector 
to simply add the name to the body of a html mail template and send the email to the relevant customer.

## Prerequisites
 
- JDK 1.8 or later
- [Ballerina Distribution](https://ballerinalang.org/docs/quick-tour/quick-tour/#install-ballerina) 
- Ballerina IDE plugins ([IntelliJ IDEA](https://plugins.jetbrains.com/plugin/9520-ballerina), 
    [VSCode](https://marketplace.visualstudio.com/items?itemName=WSO2.Ballerina), 
    [Atom](https://atom.io/packages/language-ballerina))
- [Docker](https://docs.docker.com/engine/installation/)
- Go through the following steps to obtain credetials and tokens for both Google Sheets and Gmail APIs.
    1. Visit [Google API Console](https://console.developers.google.com), click **Create Project**, and follow the wizard 
    to create a new project.
    2. Enable both Gmail and Google Sheets APIs for the project.
    3. Go to **Credentials -> OAuth consent screen**, enter a product name to be shown to users, and click **Save**.
    4. On the **Credentials** tab, click **Create credentials** and select **OAuth client ID**. 
    5. Select an application type, enter a name for the application, and specify a redirect URI 
    (enter https://developers.google.com/oauthplayground if you want to use 
    [OAuth 2.0 playground](https://developers.google.com/oauthplayground) to receive the authorization code and obtain the 
    access token and refresh token). 
    6. Click **Create**. Your client ID and client secret appear. 
    7. In a separate browser window or tab, visit [OAuth 2.0 playground](https://developers.google.com/oauthplayground), 
    select the required Gmail and Google Sheets API scopes, and then click **Authorize APIs**.
    8. When you receive your authorization code, click **Exchange authorization code for tokens** to obtain the refresh 
    token and access token.         
   
- Create a Google Sheet as follows from the same Google account you have obtained the client credentials and tokens 
to access both APIs.

![Sample googlsheet created to keep trach of product downloads by customers](images/spreadsheet.png)

- Obtain the spreadsheet id by extracting the value between the "/d/" and the "/edit" in the URL of your spreadsheet.

### Before you begin

##### Understand the package structure

Ballerina is a complete programming language that can have any custom project structure as you wish. Although the 
language allows you to have any package structure, use the following simple package structure for this project.

```
gmail-spreadsheet-integration
  ├── ballerina.conf  
  └── notification-sender
      └── notification_sender.bal
```

You must configure the `ballerina.conf` configuration file with the above obtained tokens, credentials and 
other important parameters.

##### ballerina.conf
```
ACCESS_TOKEN="enter your access token here"
CLIENT_ID="enter your client id here"
CLIENT_SECRET="enter your client secret here"
REFRESH_TOKEN="enter your refresh token here"

SPREADSHEET_ID="enter the reference spreadsheet id"
SHEET_NAME="enter the reference spreadsheet name"
SENDER="enter email sender address"
USER_ID="enter the user id. give special value 'me' for the authorized user"
```
- SPREADSHEET_ID is the spreadsheet id you have extracted from the sheet url.
- SHEET_NAME is the sheet name of your Goolgle Sheet. For example in above example, SHEET_NAME="Stats"
- SENDER is the email address of the sender.
- USER_ID is the email address of the authorized user. You can give this value as **me**.

## Developing the Program

Let's see how both of these Ballerina connectors can be used for this sample use case. 

First let's look at how to create the Google Sheets client endpoint as follows.

```ballerina
endpoint gsheets4:Client spreadsheetEP {
    clientConfig: {
        auth:{
            accessToken:accessToken,
            refreshToken:refreshToken,
            clientId:clientId,
            clientSecret:clientSecret
        }
    }
};
```

Next, let's look at how to create the Gmail client endpoint as follows.

```ballerina
endpoint Client gmailEP {
    clientConfig:{
        auth:{
            accessToken:accessToken,
            clientId:clientId,
            clientSecret:clientSecret,
            refreshToken:refreshToken
        }
    }
};
```

Note that, in the implementation, each of the above endpoint configuration parameters are read from the `ballerina.conf` file.

After creating the endpoints, let's implement the API calls inside the functions `getCustomerDetailsFromGSheet` and `sendMail`.

Let's look at how to get the sheet data about customer product downloads as follows.
```ballerina
function getCustomerDetailsFromGSheet () returns (string[][]) {
    string[][] values = [];
    //Read all the values from the sheet.
    var spreadsheetRes = spreadsheetEP -> getSheetValues(spreadsheetId, sheetName, "", "");
    match spreadsheetRes {
        string[][] vals => values = vals;
        gsheets4:SpreadsheetError e => log:printInfo(e.errorMessage);
    }
    return values;
}
```
The Spreadsheet connector's `getSheetValues` function is called from Spreadsheet endpoint by passing only the 
spreadsheet id and the sheet name. The sheet values are returned as a two dimensional string array if the request is
successful. If unsuccessful, returns a `SpreadsheetError`.

Next, let's look at how to send an email using the Gmail client endpoint.

```ballerina
function sendMail(string customerEmail, string subject, string messageBody) {
    //Create HTML message
    gmail:MessageRequest messageRequest;
    messageRequest.sender = senderEmail;
    messageRequest.subject = subject;
    messageRequest.messageBody = messageBody;
    messageRequest.recipient = customerEmail;
    messageRequest.contentType = gmail:TEXT_HTML;
    //Send mail
    var sendMessageResponse = gmailClient->sendMessage(userId, messageRequest);
    string messageId;
    string threadId;
    match sendMessageResponse {
        (string, string) sendStatus => {
            (messageId, threadId) = sendStatus;
            log:printInfo("Sent email to " + customerEmail + " with message Id: " + messageId + " and thread Id:"
                    + threadId);
        }
        gmail:GmailError e => log:printInfo(e.message);
    }
}
```

First, a new `MessageRequest` type is created and assigned the fields for sending an email. The content type of the 
message request is set as `TEXT_HTML`. Then, Gmail connector's `sendMessage` function is called by
passing the `MessageRequest` and `userId`.

The response from `sendMessage` is either a string tuple with the message ID and thread ID 
(if the message was sent successfully) or a `GmailError` (if the message was unsuccessful). The `match` operation can be 
used to handle the response if an error occurs.    

The main function in `notification_sender.bal` calls `sendNotification` function. Inside `sendNotification`, the customer 
details are taken from the sheet by first calling `getCustomerDetailsFromGSheet`. Then, the rows in the returned 
sheet are subsequently iterated. During each iteration, cell values in the first three columns are extracted for each 
row, except for the first row with column headers, and during each iteration, a custom HTML mail is created and sent for 
each customer.

```ballerina
function sendNotification() {
    //Retrieve the customer details from the spreadsheet.
    string[][] values = getCustomerDetailsFromGSheet();
    int i =0;
    //Iterate through each customer's details and send a customized email.
    foreach value in values {
        //Skip the first row as it contains header values.
        if(i > 0) {
            string productName = value[0];
            string CutomerName = value[1];
            string customerEmail = value[2];
            string subject = "Thank You for Downloading " + productName;
            sendMail(customerEmail, subject, getCustomEmailTamplate(CutomerName, productName));
        }
        i += 1;
    }
}
```

## Testing 

### <a name="try-out"></a> Try it out

Run this sample by entering the following command in a terminal.

```bash
$ ballerina run notification-sender
```

#### <a name="response"></a> Response you'll get

Each of the customers in your Google Sheet would receive a new customized email with the 
**Subject : Thank You for Downloading {ProductName}**.

The following is a sample email body.

```
    Hi Peter 
    
    Thank you for downloading the product ESB!

    If you still have questions regarding ESB, please contact us and we will get in touch with you right away!
```

Let's now look at sample log statements we get when running the sample for this scenario.

```bash
INFO  [notification-sender] - Retrieved customer details from spreadsheet id:1AH8-khPiF1dBFAs_MV5AiGDcdwFUkxOMq5ZRgBnkPW0 ;sheet name: Stats 
INFO  [notification-sender] - Sent email to tom@mail.com with message Id: 162b8e298adac15c and thread Id:162b8e298adac15c 
INFO  [notification-sender] - Sent email to jack@mail.com with message Id: 162b8e29ac7da1da and thread Id:162b8e29ac7da1da 
INFO  [notification-sender] - Sent email to peter@mail.com with message Id: 162b8e29edd1e593 and thread Id:162b8e29edd1e593 
```

## Deployment

#### Deploying locally
You can deploy the services that you developed above in your local environment. You can create the Ballerina executable archives (.balx) first and run them in your local environment as follows.

**Building**

```bash
$ ballerina build gmail-spreadsheet-integration
```

After the build is successful, there will be a .balx file inside the target directory. That executable can be executed 
as follows.

**Running**

```bash
$ ballerina run <Exec_Archive_File_Name>
```