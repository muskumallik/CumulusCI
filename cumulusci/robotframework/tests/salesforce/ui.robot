*** Settings ***

Resource        cumulusci/robotframework/Salesforce.robot
Library         cumulusci.robotframework.PageObjects
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser


*** Keywords ***

Create Account
    [Arguments]      &{fields}
    ${name} =        Generate Random String
    ${account_id} =  Salesforce Insert  Account
    ...                Name=${name}
    ...                &{fields}
    &{account} =     Salesforce Get  Account  ${account_id}
    [return]  &{account}

Create Contact
    [Arguments]      &{fields}
    ${first_name} =  Generate Random String
    ${last_name} =   Generate Random String
    ${contact_id} =  Salesforce Insert  Contact
    ...                FirstName=${first_name}
    ...                LastName=${last_name}
    ...                &{fields}
    &{contact} =     Salesforce Get  Contact  ${contact_id}
    [return]  &{contact}

*** Test Cases ***

Identify the browser
    go to  http://www.whatismybrowser.com
    capture page screenshot

Click Modal Button
    Go To Object Home            Contact
    Click Object Button          New
    Click Modal Button           Save
    ${locator} =                 Get Locator  modal.has_error
    Page Should Contain Element  ${locator}

Click Object Button
    Go To Object Home    Contact
    Click Object Button  New
    Page Should Contain  New Contact

Click Related List Button
    &{contact} =               Create Contact
    Go To Record Home          &{contact}[Id]
    Click Related List Button  Opportunities  New
    Wait Until Modal Is Open
    Page Should Contain        New Opportunity

Close Modal
    Go To Object Home        Contact
    Open App Launcher
    Close Modal
    Wait Until Modal Is Closed
    Page Should Not Contain  All Apps

Current App Should Be
    Go To Object Home        Contact
    Select App Launcher App  Service
    Current App Should Be    Service

Select App Launcher Tab
    [Documentation]  Verify that 'Select App Launcher Tab' works
    [Setup]  run keywords
    ...  load page object  Listing  User
    ...  AND  load page object  Home  Event

    Select App Launcher Tab  People
    Current page should be   Listing  User

    # Just for good measure, let's switch to another page
    # to make sure it's not a fluke and we really did
    # switch to a different page.
    Select App Launcher Tab  Calendar
    Current page should be   Home  Event

Get Current Record Id
    &{contact} =       Create Contact
    Go To Record Home  &{contact}[Id]
    ${contact_id} =    Get Current Record Id
    Should Be Equal    &{contact}[Id]  ${contact_id}

Get Related List Count
    &{account} =       Create Account
    &{fields} =        Create Dictionary
    ...                  AccountId=&{account}[Id]
    &{contact} =       Create Contact  &{fields}
    Go To Record Home  &{account}[Id]
    ${count} =         Get Related List Count  Contacts
    Should Be Equal    ${count}  ${1}

Go To Setup Home
    Go To Setup Home

Go To Setup Object Manager
    Go To Setup Object Manager

Go To Object Home
    [Tags]  smoke
    Go To Object List  Contact

Go To Object List
    [Tags]  smoke
    Go To Object List  Contact

Go To Object List With Filter
    [Tags]  smoke
    Go To Object List  Contact  filter=Recent

Go To Record Home
    [Tags]  smoke
    &{contact} =       Create Contact
    Go To Record Home  &{contact}[Id]

Header Field Should Have Value
    &{fields} =                     Create Dictionary
    ...                               Phone=1234567890
    &{account} =                    Create Account  &{fields}
    Go To Record Home               &{account}[Id]
    Header Field Should Have Value  Phone

Header Field Should Not Have Value
    &{account} =                        Create Account
    Go To Record Home                   &{account}[Id]
    Header Field Should Not Have Value  Phone

Header Field Should Have Link
    &{fields} =                    Create Dictionary
    ...                              Website=http://www.test.com
    &{account} =                   Create Account  &{fields}
    Go To Record Home              &{account}[Id]
    Header Field Should Have Link  Website

Header Field Should Not Have Link
    &{account} =                       Create Account
    Go To Record Home                  &{account}[Id]
    Header Field Should Not Have Link  Website

Click Header Field Link
    &{contact} =                       Create Contact
    Go To Record Home                  &{contact}[Id]
    Click Header Field Link            Contact Owner

Open App Launcher
    Go To Object Home    Contact
    Open App Launcher
    Page Should Contain  All Apps

Populate Field
    ${account_name} =    Generate Random String
    Go To Object Home    Account
    Click Object Button  New
    Populate Field       Account Name  ${account_name}
    ${locator} =         Get Locator  object.field  Account Name
    ${value} =           Get Value  ${locator}
    Should Be Equal      ${value}  ${account_name}
    Populate Field       Account Name  ${account_name}
    ${value} =           Get Value  ${locator}
    Should Be Equal      ${value}  ${account_name}

Populate Lookup Field
    &{account} =           Create Account
    Go To Object Home      Contact
    Click Object Button    New
    Populate Lookup Field  Account Name  &{account}[Name]
    ${locator} =           Get Locator  object.field_lookup_value  Account Name
    ${value} =             Get Text  ${locator}
    Should Be Equal        ${value}  &{account}[Name]

Populate Form
    ${account_name} =    Generate Random String
    Go To Object Home    Account
    Click Object Button  New
    Populate Form        Account Name=${account_name}
    ${locator} =         Get Locator  object.field  Account Name
    ${value} =           Get Value  ${locator}
    Should Be Equal      ${value}  ${account_name}
