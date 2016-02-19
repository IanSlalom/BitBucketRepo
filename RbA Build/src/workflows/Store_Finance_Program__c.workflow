<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Update_Finance_Company</fullName>
        <description>Updates the finance company from the finance plan to the store financing record (to make it searchable).</description>
        <field>Finance_Company__c</field>
        <formula>Finance_Program__r.Finance_Company__r.Name</formula>
        <name>Update Finance Company</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Finance_Program_Name</fullName>
        <description>Puts the finance program name in a text field to make it searchable from order financing</description>
        <field>Finance_Program_Name__c</field>
        <formula>Finance_Program__r.Name</formula>
        <name>Update Finance Program Name</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Plan_Number</fullName>
        <description>Updates the plan number from the finance plan to the store financing record. (to make it searchable)</description>
        <field>Plan_Number__c</field>
        <formula>Finance_Program__r.Plan_Number__c</formula>
        <name>Update Plan Number</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Store Finance Program Updated</fullName>
        <actions>
            <name>Update_Finance_Company</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Update_Finance_Program_Name</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Update_Plan_Number</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>Fires any time a store finance program is updated.</description>
        <formula>true</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
