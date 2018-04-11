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

import ballerina/log;
import wso2/gmail;

documentation{
    GMail client endpoint declaration with oAuth2 client configurations
}
endpoint gmail:Client gMailEP {
    oAuth2ClientConfig:{
        accessToken:accessToken,
        clientId:clientId,
        clientSecret:clientSecret,
        refreshToken:refreshToken
    }
};

documentation{
    Sends a mail with the given message body to the specified recipient for dowloading the specified product.

    P{{recipient}} - Recipient customer's email address.
    P{{productName}} - Product name which the customer has downloaded.
    P{{messageBody}} - Email message body to send.
}
function sendMail(string recipient, string productName, string messageBody) {
    //---Create the html message---
    string subject = "Thank You for Downloading " + productName;
    gmail:MessageOptions options = {};
    options.sender = senderEmail;
    gmail:Message mail = new gmail:Message();
    match mail.createHTMLMessage(recipient, subject, messageBody, options, []){
        gmail:GMailError e => log:printInfo(e.errorMessage);
        () => {
            //----Send the mail----
            log:printInfo("gMailEP -> sendMessage()");
            var sendMessageResponse = gMailEP -> sendMessage(userId, mail);
            string messageId;
            string threadId;
            match sendMessageResponse {
                (string, string) sendStatus => {
                    (messageId, threadId) = sendStatus;
                    log:printInfo("Sent message Id: " + messageId);
                    log:printInfo("Send thread Id:" + threadId);
                }
                gmail:GMailError e => log:printInfo(e.errorMessage);
            }
        }
    }
}
