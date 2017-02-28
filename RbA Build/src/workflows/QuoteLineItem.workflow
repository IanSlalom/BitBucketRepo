<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Quote_Line_Item_HW_Option_Default</fullName>
        <field>Hardware_Option__c</field>
        <formula>&quot;Normal Hinge&quot;</formula>
        <name>Quote Line Item HW Option Default</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
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
        <fullName>Quote Line Item HW Option Default</fullName>
        <actions>
            <name>Quote_Line_Item_HW_Option_Default</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Product2.Name</field>
            <operation>contains</operation>
            <value>Casement</value>
        </criteriaItems>
        <criteriaItems>
            <field>QuoteLineItem.Hardware_Option__c</field>
            <operation>equals</operation>
        </criteriaItems>
        <description>Sets the default of Hardware Option to Normal Hinge for Casement Windows</description>
        <triggerType>onAllChanges</triggerType>
    </rules>
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
