/*
* Copyright 2010-2016 Amazon.com, Inc. or its affiliates. All Rights Reserved.
*
* Licensed under the Apache License, Version 2.0 (the "License").
* You may not use this file except in compliance with the License.
* A copy of the License is located at
*
*  http://aws.amazon.com/apache2.0
*
* or in the "license" file accompanying this file. This file is distributed
* on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
* express or implied. See the License for the specific language governing
* permissions and limitations under the License.
*/

import Foundation
import AWSCore

//WARNING: To run this sample correctly, you must set the following constants.
let AwsRegion = AWSRegionType.USEast2 // e.g. AWSRegionType.USEast1
let CognitoIdentityPoolId = "us-east-2:7f58da0e-5665-4063-9d86-356066fd46cd"
let CertificateSigningRequestCommonName = "IoTSampleSwift Application"
let CertificateSigningRequestCountryName = "US"
let CertificateSigningRequestOrganizationName = "Root"
let CertificateSigningRequestOrganizationalUnitName = "Petal"
let PolicyName = "AWSIoTFullAccess" //or maybe "FullAWSAccess"
//This is the endpoint in your AWS IoT console. eg: https://xxxxxxxxxx.iot.<region>.amazonaws.com
let IOT_ENDPOINT = "https://a3nxzzc72rdj05.iot.us-east-2.amazonaws.com"
