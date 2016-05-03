<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Set_Billable_Amount_when_Quote_Accepted</fullName>
        <field>Billable_Amount__c</field>
        <formula>Quote_Amount__c</formula>
        <name>Set Billable Amount when Quote Accepted</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Set Billable Amount when Quote Accepted</fullName>
        <actions>
            <name>Set_Billable_Amount_when_Quote_Accepted</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>OrderItem.Quote_Accepted__c</field>
            <operation>equals</operation>
            <value>True</value>
        </criteriaItems>
        <description>For Service Products</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
</Workflow>
