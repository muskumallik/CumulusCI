*** Settings ***

Resource       cumulusci/robotframework/Salesforce.robot
Suite Teardown  Delete Session Records

*** Keywords ***

Create Contact
    ${first_name} =  Generate Random String
    ${last_name} =  Generate Random String
    ${contact_id} =  Salesforce Insert  Contact  FirstName=${first_name}  LastName=${last_name}
    &{contact} =  Salesforce Get  Contact  ${contact_id}
    [return]  &{contact}

*** Test Cases ***

Salesforce Insert Perf
    ${first_name} =  Generate Random String
    ${last_name} =  Generate Random String
    ${contact_id} =  Salesforce Insert Perf     Xyzzy   Contact
    ...  FirstName=${first_name}
    ...  LastName=${last_name}
    &{contact} =  Salesforce Get  Contact  ${contact_id}
    Should Be Equal  &{contact}[FirstName]  ${first_name}
    Should Be Equal  &{contact}[LastName]  ${last_name}
