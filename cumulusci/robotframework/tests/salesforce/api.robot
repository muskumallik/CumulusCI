*** Settings ***

Resource       cumulusci/robotframework/Salesforce.robot
Suite Teardown  Delete Session Records

*** Keywords ***

Create Contact
    ${first_name} =  Generate Random String
    ${last_name} =  Generate Random String
    ${contact_id} =  Salesforce Insert  Contact  FirstName=${first_name}  LastName=${last_name} kwId=TestCreateContactKW
    &{contact} =  Salesforce Get  Contact  ${contact_id}
    [return]  &{contact}

*** Test Cases ***

Salesforce Delete Test
    Log Variables
    &{contact} =  Create Contact
    Salesforce Delete  Contact  &{contact}[Id]  kwId=TestDeleteKW
    &{result} =  SOQL Query  Select Id from Contact WHERE Id = '&{contact}[Id]'    kwId=TestDeleteSOQLKW
    Should Be Equal  &{result}[totalSize]  ${0}

Salesforce Insert Test
    ${first_name} =  Generate Random String
    ${last_name} =  Generate Random String
    ${contact_id} =  Salesforce Insert  Contact     kwId=TestInsertKW
    ...  FirstName=${first_name}
    ...  LastName=${last_name}
    &{contact} =  Salesforce Get  Contact  ${contact_id}    kwId=TestGetofInsertedKW
    Should Be Equal  &{contact}[FirstName]  ${first_name}
    Should Be Equal  &{contact}[LastName]  ${last_name}

Salesforce Update Test
    &{contact} =  Create Contact
    ${new_last_name} =  Generate Random String
    Salesforce Update  Contact  &{contact}[Id]  LastName=${new_last_name}   kwId=TestUpdateKW
    &{contact} =  Salesforce Get  Contact  &{contact}[Id]
    Should Be Equal  &{contact}[LastName]  ${new_last_name}

Salesforce Query Test
    &{new_contact} =  Create Contact
    @{records} =  Salesforce Query  Contact    kwId=TestQueryKW
    ...              select=Id,FirstName,LastName
    ...              Id=&{new_contact}[Id]
    &{contact} =  Get From List  ${records}  0
    Should Be Equal  &{contact}[Id]  &{new_contact}[Id]
    Should Be Equal  &{contact}[FirstName]  &{new_contact}[FirstName]
    Should Be Equal  &{contact}[LastName]  &{new_contact}[LastName]

SOQL Query Test
    &{new_contact} =  Create Contact
    &{result} =  Soql Query  Select Id, FirstName, LastName from Contact WHERE Id = '&{new_contact}[Id]'       kwId=TestSOQLTestKW
    @{records} =  Get From Dictionary  ${result}  records
    Log Variables
    &{contact} =  Get From List  ${records}  0
    Should Be Equal  &{result}[totalSize]  ${1}
    Should Be Equal  &{contact}[FirstName]  &{new_contact}[FirstName]
    Should Be Equal  &{contact}[LastName]  &{new_contact}[LastName]
