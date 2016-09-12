<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Update_Program_Fee</fullName>
        <description>The program fee (percentage) times the amount financed. Executing this in a workflow so we can using the master-detail rollup to the order.</description>
        <field>Program_Fee__c</field>
        <formula>Store_Finance_Program__r.Program_Fee__c *  Amount_Financed__c</formula>
        <name>Update Program Fee</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Order Financing Updated</fullName>
        <actions>
            <name>Update_Program_Fee</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>true</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
