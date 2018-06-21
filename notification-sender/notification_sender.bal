// Copyright (c) 2018 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/config;
import ballerina/log;
import wso2/gsheets4;
import wso2/gmail;

documentation{A valid access token with gmail and google sheets access.}
string accessToken = config:getAsString("ACCESS_TOKEN");

documentation{The client ID for your application.}
string clientId = config:getAsString("CLIENT_ID");

documentation{The client secret for your application.}
string clientSecret = config:getAsString("CLIENT_SECRET");

documentation{A valid refreshToken with gmail and google sheets access.}
string refreshToken = config:getAsString("REFRESH_TOKEN");

documentation{Spreadsheet id of the reference google sheet.}
string spreadsheetId = config:getAsString("SPREADSHEET_ID");

documentation{Sheet name of the reference googlle sheet.}
string sheetName = config:getAsString("SHEET_NAME");

documentation{Sender email address.}
string senderEmail = config:getAsString("SENDER");

documentation{The user's email address.}
string userId = config:getAsString("USER_ID");

documentation{
    Google Sheets client endpoint declaration with http client configurations.
}
endpoint gsheets4:Client spreadsheetClient {
    clientConfig: {
        auth: {
            accessToken: accessToken,
            refreshToken: refreshToken,
            clientId: clientId,
            clientSecret: clientSecret
        }
    }
};

documentation{
    GMail client endpoint declaration with oAuth2 client configurations.
}
endpoint gmail:Client gmailClient {
    clientConfig: {
        auth: {
            accessToken: accessToken,
            refreshToken: refreshToken,
            clientId: clientId,
            clientSecret: clientSecret
        }
    }
};

function main(string... args) {
    sendNotification();
}

documentation{
    Send notification to the customers.
}
function sendNotification() {
    //Retrieve the customer details from spreadsheet.
    string[][] values = getCustomerDetailsFromGSheet();
    int i = 0;
    //Iterate through each customer details and send customized email.
    foreach value in values {
        //Skip the first row as it contains header values.
        if (i > 0) {
            string productName = value[0];
            string CutomerName = value[1];
            string customerEmail = value[2];
            string subject = "Thank You for Downloading " + productName;
            sendMail(customerEmail, subject, getCustomEmailTemplate(CutomerName, productName));
        }
        i = i + 1;
    }
}

documentation{
    Retrieves customer details from the spreadsheet statistics.

    R{{}} - Two dimensional string array of spreadsheet cell values.
}
function getCustomerDetailsFromGSheet() returns (string[][]) {
    //Read all the values from the sheet.
    string[][] values = check spreadsheetClient->getSheetValues(spreadsheetId, sheetName, "", "");
    log:printInfo("Retrieved customer details from spreadsheet id:" + spreadsheetId + " ;sheet name: "
            + sheetName);
    return values;
}

documentation{
    Get the customized email template.

    P{{customerName}} - Name of the customer.
    P{{productName}} - Name of the product which the customer has downloaded.
    R{{}} - String customized email message.
}
function getCustomEmailTemplate(string customerName, string productName) returns (string) {
    string emailTemplate = "<h2> Hi " + customerName + " </h2>";
    emailTemplate = emailTemplate + "<h3> Thank you for downloading the product " + productName + " ! </h3>";
    emailTemplate = emailTemplate + "<p> If you still have questions regarding " + productName +
        ", please contact us and we will get in touch with you right away ! </p> ";
    return emailTemplate;
}

documentation{
    Send email with the given message body to the specified recipient for dowloading the specified product.

    P{{customerEmail}} - Recipient's email address.
    P{{subject}} - Subject of the email.
    P{{messageBody}} - Email message body to send.
}
function sendMail(string customerEmail, string subject, string messageBody) {
    //Create html message
    gmail:MessageRequest messageRequest;
    messageRequest.recipient = customerEmail;
    messageRequest.sender = senderEmail;
    messageRequest.subject = subject;
    messageRequest.messageBody = messageBody;
    messageRequest.contentType = gmail:TEXT_HTML;

    //Send mail
    var sendMessageResponse = gmailClient->sendMessage(userId, untaint messageRequest);
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
