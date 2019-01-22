[![Build Status](https://travis-ci.org/ballerina-guides/gmail-spreadsheet-integration.svg?branch=master)](https://travis-ci.org/ballerina-guides/gmail-spreadsheet-integration)

# GMail-Google Sheets Integration

[Google Sheets](https://www.google.com/sheets/about/) is an online spreadsheet that lets users create and format 
spreadsheets and simultaneously work with other people. [GMail](https://www.google.com/gmail/) is a free, web-based
e-mail service provided by Google.

> This guide walks you through the process of using Google Sheets and GMail using Ballerina language.

The following are the sections available in this guide.

- [What you'll build](#what-youll-build)
- [Prerequisites](#prerequisites)
- [Implementation](#implemtation)
- [Testing](#testing)
- [Deployment](#deployment)

## What you’ll build

To understand how you can use Ballerina API connectors, in this sample we use Spreadsheet connector to get 
data from a Google Sheet and send those data in an email using GMail connector.

Let us consider a real world use case scenario of a software product company. When a customer downloads the 
product from the company website, providing the name and email address, the company sends a customized email to the 
customer’s mailbox saying,

```
    Hi <CustomerName>
    
    Thank you for downloading the product <ProductName>!

    If you still have questions regarding <ProductName>, please contact us and we will get in touch with you right away!                                        
```
The product name, customer name and email address are added to the first, second and third columns of a Google Sheet.

![GMail-Spreadsheet Integration Overview](images/gmail_spreadsheet_integration.svg)

You can use the Ballerina Google Spreadsheet connector to read the spreadsheet, iterate through the rows and pick 
up the product name, email address and name of each customer from the columns. Then, you can use the GMail connector
to simply add the name to the body of a html mail template and send the email to the relevant customer.

## Prerequisites
 
- [Ballerina Distribution](https://ballerina.io/learn/getting-started/)
- A Text Editor or an IDE 
> **Tip**: You can install the following Ballerina IDE plugins: [VSCode](https://marketplace.visualstudio.com/items?itemName=ballerina.ballerina), [IntelliJ IDEA](https://plugins.jetbrains.com/plugin/9520-ballerina)
- Go through the following steps to obtain credetials and tokens for both Google Sheets and GMail APIs.
    1. Visit [Google API Console](https://console.developers.google.com), click **Create Project**, and follow the wizard 
    to create a new project.
    2. Enable both GMail and Google Sheets APIs for the project.
    3. Go to **Credentials -> OAuth consent screen**, enter a product name to be shown to users, and click **Save**.
    4. On the **Credentials** tab, click **Create credentials** and select **OAuth client ID**. 
    5. Select an application type, enter a name for the application, and specify a redirect URI 
    (enter https://developers.google.com/oauthplayground if you want to use 
    [OAuth 2.0 playground](https://developers.google.com/oauthplayground) to receive the authorization code and obtain the 
    access token and refresh token). 
    6. Click **Create**. Your client ID and client secret appear. 
    7. In a separate browser window or tab, visit [OAuth 2.0 playground](https://developers.google.com/oauthplayground), 
    select the required GMail and Google Sheets API scopes, and then click **Authorize APIs**.
    8. When you receive your authorization code, click **Exchange authorization code for tokens** to obtain the refresh 
    token and access token.         

  You must configure the `ballerina.conf` configuration file with the above obtained tokens, credentials and 
  other important parameters as follows.
  ```
  ACCESS_TOKEN="access token"
  CLIENT_ID="client id"
  CLIENT_SECRET="client secret"
  REFRESH_TOKEN="refresh token"
  SPREADSHEET_ID="spreadsheet id you have extracted from the sheet url"
  SHEET_NAME="sheet name of your Goolgle Sheet. For example in above example, SHEET_NAME="Stats"
  SENDER="email address of the sender"
  USER_ID="mail address of the authorized user. You can give this value as, me"
  ```

- Create a Google Sheet as follows from the same Google account you have obtained the client credentials and tokens 
to access both APIs.

![Sample googlsheet created to keep trach of product downloads by customers](images/spreadsheet.png)

- Obtain the spreadsheet id by extracting the value between the "/d/" and the "/edit" in the URL of your spreadsheet.

    
## Implementation

### Create the module structure

Ballerina is a complete programming language that can have any custom project structure as you wish. Although the 
language allows you to have any module structure, use the following simple module structure for this project.

```
gmail-spreadsheet-integration
  ├── ballerina.conf  
  └── notification-sender
      └── tests
          └── notification_sender_test.bal
      └── notification_sender.bal
```

### Developing the application 
Let's see how both of these Ballerina connectors can be used for this sample use case. 

First let's look at how to create the Google Sheets client endpoint as follows.

```ballerina
gsheets4:Client spreadsheetClient = new({
    clientConfig: {
        auth: {
            scheme: http:OAUTH2,
            accessToken: accessToken,
            refreshToken: refreshToken,
            clientId: clientId,
            clientSecret: clientSecret
        }
    }
});
```

Next, let's look at how to create the GMail client endpoint as follows.

```ballerina
gmail:Client gmailClient = new({
    clientConfig: {
        auth: {
            scheme: http:OAUTH2,
            accessToken: accessToken,
            refreshToken: refreshToken,
            clientId: clientId,
            clientSecret: clientSecret
        }
    }
});
```

Note that, in the implementation, each of the above endpoint configuration parameters are read from the `ballerina.conf` file.

After creating the endpoints, let's implement the API calls inside the functions `getCustomerDetailsFromGSheet` and `sendMail`.

Let's look at how to get the sheet data about customer product downloads as follows.
```ballerina
function getCustomerDetailsFromGSheet() returns string[][]|error {
    //Read all the values from the sheet.
    string[][] values = check spreadsheetClient->getSheetValues(spreadsheetId, sheetName);
    log:printInfo("Retrieved customer details from spreadsheet id: " + spreadsheetId + " ; sheet name: "
            + sheetName);
    return values;
}
```

The Spreadsheet connector's `getSheetValues` function is called from Spreadsheet endpoint by passing the spreadsheet id and the sheet name. The sheet values are returned as a two dimensional string array if the request is
successful. If unsuccessful, it returns a `SpreadsheetError`.

Next, let's look at how to send an email using the GMail client endpoint.

```ballerina
function sendMail(string customerEmail, string subject, string messageBody) returns boolean {
    //Create html message
    gmail:MessageRequest messageRequest = {}
    messageRequest.recipient = customerEmail;
    messageRequest.sender = senderEmail;
    messageRequest.subject = subject;
    messageRequest.messageBody = messageBody;
    messageRequest.contentType = gmail:TEXT_HTML;

    //Send mail
    var sendMessageResponse = gmailClient->sendMessage(userId, untaint messageRequest);
    string messageId;
    string threadId;
    if (sendMessageResponse is (string, string)) {
        (messageId, threadId) = sendMessageResponse;
        log:printInfo("Sent email to " + customerEmail + " with message Id: " + messageId +
            " and thread Id:" + threadId);
        return true;
    } else {
        log:printInfo(<string>sendMessageResponse.detail().message);
        return false;
    }
}
```

First, a new `MessageRequest` type is created and assigned the fields for sending an email. The content type of the message request is set as `TEXT_HTML`. Then, GMail connector's `sendMessage` function is called by passing the `MessageRequest` and `userId`.

The response from `sendMessage` is either a string tuple with the message ID and thread ID (if the message was sent successfully) or a `GmailError` (if the message was unsuccessful). The `match` operation can be used to handle the response if an error occurs.    

The main function in `notification_sender.bal` calls `sendNotification` function. Inside `sendNotification`, the customer details are taken from the sheet by first calling `getCustomerDetailsFromGSheet`. Then, the rows in the returned sheet are subsequently iterated. During each iteration, cell values in the first three columns are extracted for each row, except for the first row with column headers, and during each iteration, a custom HTML mail is created and sent for each customer.

```ballerina
function sendNotification() returns boolean {
    //Retrieve the customer details from spreadsheet.
    var customerDetails = getCustomerDetailsFromGSheet();
    if (customerDetails is error) {
        log:printError("Failed to retrieve customer details from GSheet", err = customerDetails);
        return false;
    } else {
        int i = 0;
        boolean isSuccess = false;
        //Iterate through each customer details and send customized email.
        foreach var value in customerDetails {
            //Skip the first row as it contains header values.
            if (i > 0) {
                string productName = value[0];
                string CutomerName = value[1];
                string customerEmail = value[2];
                string subject = "Thank You for Downloading " + productName;
                isSuccess = sendMail(customerEmail, subject, getCustomEmailTemplate(CutomerName, productName));
                if (!isSuccess) {
                    break;
                }
            }
            i += 1;
        }
        return isSuccess;
    }
}
```

## Testing 

### Try it out

Run this sample by entering the following command in a terminal.

```bash
$ ballerina run notification-sender
```

Each of the customers in your Google Sheet would receive a new customized email with the subject: **Thank You for Downloading {ProductName}**.

The following is a sample email body.

```
    Hi Peter 
    
    Thank you for downloading the product ESB!

    If you still have questions regarding ESB, please contact us and we will get in touch with you right away!

```

Let's now look at sample log statements we get when running the sample for this scenario.

```bash
INFO  [wso2.notification-sender] - Retrieved customer details from spreadsheet id: 1mzEKVRtL3ZGV0finbcd1vfa16Ed7Qaa6wBjsf31D_yU; sheet name: Stats
INFO  [wso2.notification-sender] - Sent email to tom@mail.com with message Id: 163014e0e41c1b11 and thread Id:163014e0e41c1b11 
INFO  [wso2.notification-sender] - Sent email to jack@mail.com with message Id: 163014e1167c20c4 and thread Id:163014e1167c20c4 
INFO  [wso2.notification-sender] - Sent email to peter@mail.com with message Id: 163014e15d7476a0 and thread Id:163014e15d7476a0 
INFO  [wso2.notification-sender] - GMail-Google Sheets Integration -> Email sending process successfully completed!

```

### Writing unit tests    

In Ballerina, the unit test cases should be in the same module inside a folder named as 'tests'.  When writing the test
functions the below convention should be followed.

- Test functions should be annotated with `@test:Config`. See the below example.
```ballerina
   @test:Config
   function testSendNotification() {
```
  
This guide contains the unit test case for the `sendNotification` function.

To run the unit test, go to the sample root directory and run the following command.
```bash
$ ballerina test --config ./ballerina.conf notification-sender
```
   
Refer to the `notification-sender/tests/notification_sender_test.bal` for the implementation of the test file.

## Deployment

#### Deploying locally
You can deploy the services that you developed above in your local environment. You can create the Ballerina executable archives (.balx) first as follows.

**Building**

```bash
$ ballerina build notification-sender
```

After the build is successful, there will be a .balx file inside the target directory. That executable can be executed 
as follows.

**Running**

```bash
$ ballerina run --config ./ballerina.conf target/notification-sender.balx
```
