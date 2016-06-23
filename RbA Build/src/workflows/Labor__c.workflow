<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Set_Hourly_Rate_on_Labor_Record</fullName>
        <description>Sets the hourly rate on a labor record based on the active store configuration</description>
        <field>Hourly_Rate__c</field>
        <formula>Store_Location__r.Active_Store_Configuration__r.Standard_Hourly_Rate__c</formula>
        <name>Set Hourly Rate on Labor Record</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Labor Record Created</fullName>
        <actions>
            <name>Set_Hourly_Rate_on_Labor_Record</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>true</formula>
        <triggerType>onCreateOnly</triggerType>
    </rules>
</Workflow>
