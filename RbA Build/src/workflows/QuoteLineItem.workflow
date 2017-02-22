<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Set_Rollup_Subtotal</fullName>
        <field>Roll_Up_Subtotal__c</field>
        <formula>Quantity * UnitPrice</formula>
        <name>Set Rollup Subtotal</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Set Rollup Subtotal</fullName>
        <actions>
            <name>Set_Rollup_Subtotal</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>ISCHANGED(Quantity)|| NOT(ISBLANK(Quantity))</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
