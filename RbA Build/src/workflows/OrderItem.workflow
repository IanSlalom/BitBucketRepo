<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Paint_Stain_Order_Product</fullName>
        <field>Paint_Stain__c</field>
        <literalValue>1</literalValue>
        <name>Paint &amp; Stain Order Product</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Billable_Amount_when_Quote_Accepted</fullName>
        <field>Billable_Amount__c</field>
        <formula>Quote_Amount__c</formula>
        <name>Set Billable Amount when Quote Accepted</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Billable_Amount_when_Quote_Unchecked</fullName>
        <field>Billable_Amount__c</field>
        <formula>0</formula>
        <name>Set Billable Amount when Quote Unchecked</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Paint %26 Stain Order Product</fullName>
        <actions>
            <name>Paint_Stain_Order_Product</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Product2.Name</field>
            <operation>equals</operation>
            <value>Paint/Stain</value>
        </criteriaItems>
        <criteriaItems>
            <field>OrderItem.Paint_Stain__c</field>
            <operation>equals</operation>
            <value>False</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
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
    <rules>
        <fullName>Set Billable Amount when Quote Accepted Unchecked</fullName>
        <actions>
            <name>Set_Billable_Amount_when_Quote_Unchecked</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>OrderItem.Quote_Accepted__c</field>
            <operation>equals</operation>
            <value>False</value>
        </criteriaItems>
        <description>When Quote Accepted goes from checked to unchecked, set Billable Amount back to 0</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
</Workflow>
