<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Set_PO_Number</fullName>
        <description>Uses an auto-number and the abbreviation field on the PO to create the PO Name.</description>
        <field>Name</field>
        <formula>IF( ISBLANK(Store_Abbreviation__c), &apos;XX&apos;, Store_Abbreviation__c) &amp;  
&apos;-&apos; &amp;
PO_System_Number__c</formula>
        <name>Set PO Number</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Purchase Order Created</fullName>
        <actions>
            <name>Set_PO_Number</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>Fires every time a po is created.</description>
        <formula>true</formula>
        <triggerType>onCreateOnly</triggerType>
    </rules>
</Workflow>
