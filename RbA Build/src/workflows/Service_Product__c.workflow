<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Set_Service_Product_Name</fullName>
        <field>Name</field>
        <formula>Service_Product__r.Name</formula>
        <name>Set Service Product Name</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Service_Product_Record_Name_Unique</fullName>
        <field>Record_Name_Unique__c</field>
        <formula>Service_Product__r.Name +&apos; &apos;+ Master_Product__r.Name</formula>
        <name>Set Service Product Record Name Unique</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Set Service Product Name</fullName>
        <actions>
            <name>Set_Service_Product_Name</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>true</formula>
        <triggerType>onCreateOnly</triggerType>
    </rules>
    <rules>
        <fullName>Unique Service Product</fullName>
        <actions>
            <name>Set_Service_Product_Record_Name_Unique</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>Cannot have two Service Product records with the same Master Product and Service Product combination</description>
        <formula>true</formula>
        <triggerType>onCreateOnly</triggerType>
    </rules>
</Workflow>
