<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Set_Account_Name</fullName>
        <field>Name</field>
        <formula>ShippingPostalCode + &quot;, &quot; +  ShippingStreet</formula>
        <name>Set Account Name</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Set Account Name</fullName>
        <actions>
            <name>Set_Account_Name</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <criteriaItems>
            <field>Account.RecordTypeId</field>
            <operation>equals</operation>
            <value>Dwelling</value>
        </criteriaItems>
        <description>Postal Code, Street Address</description>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
