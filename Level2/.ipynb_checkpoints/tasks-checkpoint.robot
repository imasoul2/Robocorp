*** Settings ***
Documentation     Programmer: CJ Jang    Date: 28/10/2021   Purpose: For Robocorp certification level 2 exam
...               Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.

# library needed for this task
Library           RPA.Browser.Selenium
Library           RPA.HTTP
Library           RPA.Excel.Files
Library           RPA.PDF
Library           RPA.Tables
Library           RPA.Archive
Library           RPA.Dialogs
Library           RPA.Robocorp.Vault
Library    Collections
Library    Dialogs
Library    RPA.Robocloud.Secrets



*** Keywords ***

Open the robot order website
    [Documentation]      Open up the robot-order page directly
    [Arguments]        ${url}
    Open Available Browser    ${url}        
    # https://robotsparebinindustries.com/#/robot-order
    # maybe navigate from the homepage?


Ask for Input
    Add heading    uiser input required
    Add text input    url   label=enter the url
    ${result}=    Run dialog
    [Return]    ${result.url}

Get orders
    [Documentation]      Download csv file and return the content of csv file as the table that can be looped
    Download    https://robotsparebinindustries.com/orders.csv   overwrite=True   
    ${csv_table}=    Read table from CSV    orders.csv    header=True
    [Return]    ${csv_table}

Close the annoying modal
    [Documentation]  Disable the popup by clicking "Yes"
    Click Button    OK

Fill the form
    [Documentation]  Fillout the form according to the given arguments
    [Arguments]  ${head}  ${body}   ${legs}   ${ship_to_address}
    Select From List By Value    id:head    ${head}
    Select Radio Button    body    ${body}
    Input Text     css:input[type="number"]     ${legs}
    Input Text    css:input[name="address"]     ${ship_to_address}

Preview the robot
    [Documentation]  Click Preview 
    Click Button    Preview  

Click Submit
    Click Button    Order
    Element Should Be Visible    id:order-completion

Submit the order
    [Documentation]  Submit order with 5 retries if it fails
    Wait Until Keyword Succeeds    5x    1 sec    Click Submit



Store the receipt as a PDF file  
    [Documentation]  Takes in the order number and export the receipt as pdf.
    [Arguments]     ${ordernumber}
    Wait Until Element Is Visible   id:order-completion
    ${receipt_html}=    Get Element Attribute    id:order-completion   outerHTML
    # how do i set str variable for path?
    Html To Pdf    ${receipt_html}    ${CURDIR}${/}output${/}receipt_order_${ordernumber}.pdf
    
    [Return]    ${CURDIR}${/}output${/}receipt_order_${ordernumber}.pdf
Take a screenshot of the robot
    [Documentation]  Takes a screenshot of the preview robot
    [Arguments]    ${ordernumber}
    Wait Until Element Is Visible   id:robot-preview
    Screenshot    id:robot-preview-image  ${CURDIR}${/}output${/}img_robot_order_${ordernumber}.PNG  

    [Return]    ${CURDIR}${/}output${/}img_robot_order_${ordernumber}.png  

Embed the robot screenshot to the receipt PDF file    
    [Documentation]    
    [Arguments]    ${screenshot_path}    ${pdf_path}
    Open Pdf    ${pdf_path}
    ${dummy_list}=    Create List  ${screenshot_path}   
    Add Files To Pdf    ${dummy_list}    ${pdf_path}
    Close Pdf    ${pdf_path}



Go to order another robot
    Click Button    order-another


Create a ZIP file of the receipts
    Archive Folder With Zip    folder=${CURDIR}${/}output${/}    archive_name=orders_archive.zip  include=*.pdf


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    
    # this part is to demonstrate that I can read local vault data
    ${vault_data}=   Get Secret    vault_data
    Log Many  ${vault_data}
      
    

    ${userinput}=    Ask for Input

    # Another way of asking for user input to set URL of the website
    # ${url}=    Get Value From User    "Enter the URL"

    # The template below was given by the exercise
    Open the robot order website    ${userinput}
    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}[Head]  ${row}[Body]   ${row}[Legs]   ${row}[Address]
        Preview the robot
        Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Create a ZIP file of the receipts
