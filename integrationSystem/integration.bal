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

public function main(string[] args) {
    //Retrieve the user details from spreadsheet
    log:printInfo("Started to retrieve customer details from spreadsheet id:" + spreadsheetId + " ;spreasheet name: "
            + sheetName);
    string[][] values = getCustomerDetailsFromGSheet();
    int i = 1;
    //Iterate each row of the sheet, extract details and send customized email to each customer
    foreach value in values {
        //Skip the first row with column headers in the sheet
        if (i > 1) {
            string productName = value[0];
            log:printInfo("Reading sheet row : " + i + " ProductName column value : " + productName);
            string customerName = value[1];
            log:printInfo("Reading sheet row : " + i + " CutomerName column value : " + customerName);
            string customerEmail = value[2];
            log:printInfo("Reading sheet row : " + i + " CustomerEmail column value : " + customerEmail);

            string customMessage = getCustomEmailFromTemplate(customerName, productName);
            log:printInfo("Sending custom email to: " + customerEmail + " with message: " + customMessage);
            sendMail(customerEmail, productName, customMessage);
        }
        i += 1;
    }
}
