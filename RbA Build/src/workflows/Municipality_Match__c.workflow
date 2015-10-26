<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Update_Duplicate_Catch_Field</fullName>
        <description>Update Duplicate Catch Field</description>
        <field>Duplicate_Value_Catcher__c</field>
        <formula>Agency_Name__c +  City_Township__c +  Zip_Code__c</formula>
        <name>Update Duplicate Catch Field</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Municipality Match Duplicate Catch</fullName>
        <actions>
            <name>Update_Duplicate_Catch_Field</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>Municipality Match Duplicate Catch</description>
        <formula>True</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
