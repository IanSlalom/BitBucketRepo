<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Set_Procedure_Code_Assignment_Name</fullName>
        <field>Name</field>
        <formula>LEFT(Procedure_Code__r.Name  + &apos; - &apos; + Description__c,80)</formula>
        <name>Set Procedure Code Assignment Name</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Set Procedure Code Assignment Name</fullName>
        <actions>
            <name>Set_Procedure_Code_Assignment_Name</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>true</formula>
        <triggerType>onCreateOnly</triggerType>
    </rules>
</Workflow>
