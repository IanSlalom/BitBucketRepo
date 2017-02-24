<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Set_Asset_Name</fullName>
        <field>Name</field>
        <formula>Product2.Name</formula>
        <name>Set Asset Name</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Set Asset Name</fullName>
        <actions>
            <name>Set_Asset_Name</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Asset.Legacy_Asset__c</field>
            <operation>equals</operation>
            <value>True</value>
        </criteriaItems>
        <criteriaItems>
            <field>Product2.Name_Part_Number__c</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <description>For Assets creating during Service Requests</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
</Workflow>
