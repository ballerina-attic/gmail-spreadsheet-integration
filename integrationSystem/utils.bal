// Copyright (c) 2018, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

documentation{
    Gets the customized email body from email template.

    P{{customerName}} - Name of the customer to send the mail for.
    P{{productName}} - Name of the product which the customer has downloaded.
    R{{}} - String customized email message body
}
function getCustomEmailFromTemplate(string customerName, string productName) returns (string){
    string emailBody = "<h2> Hi "+ customerName +" </h2>";
    emailBody = emailBody + "<h3> Thank you for downloading the product " + productName + " ! </h3>";
    emailBody = emailBody + "<p> If you still have questions regarding "+ productName + ", please contact us and we" +
                " will get in touch with you right away ! </p> ";
    return emailBody;
}

documentation{clientId of the google api console project}
string clientId = config:getAsString("CLIENT_ID") but { () => "" };
documentation{clientSecret of the google api console project}
string clientSecret = config:getAsString("CLIENT_SECRET") but { () => "" };
documentation{accessToken for gmail and google sheets api access}
string accessToken = config:getAsString("ACCESS_TOKEN") but { () => "" };
documentation{refreshToken for gmail and google sheets api access}
string refreshToken = config:getAsString("REFRESH_TOKEN") but { () => "" };
documentation{spreadsheet id of the reference google sheet}
string spreadsheetId = config:getAsString("SPREADSHEET_ID") but { () => "" };
documentation{sheet name of the reference googlle sheet}
string sheetName = config:getAsString("SHEET_NAME") but { () => "" };
documentation{Sender email address}
string senderEmail = config:getAsString("SENDER") but { () => "" };
documentation{The user's email address}
string userId = config:getAsString("USER_ID") but { () => "" };
