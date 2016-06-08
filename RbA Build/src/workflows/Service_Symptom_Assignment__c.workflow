<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Set_Service_Symptom_Assignment_Name</fullName>
        <field>Name</field>
        <formula>Service_Symptom__r.Name</formula>
        <name>Set Service Symptom Assignment Name</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Set Service Symptom Assignment Name</fullName>
        <actions>
            <name>Set_Service_Symptom_Assignment_Name</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>true</formula>
        <triggerType>onCreateOnly</triggerType>
    </rules>
</Workflow>
