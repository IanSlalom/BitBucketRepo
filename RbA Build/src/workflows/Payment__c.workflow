<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Set_Payment_Type_to_Deposit</fullName>
        <description>Sets the payment type to deposit</description>
        <field>Payment_Type__c</field>
        <literalValue>Deposit</literalValue>
        <name>Set Payment Type to Deposit</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Payment_Type_to_Final_Payment</fullName>
        <description>Sets the payment type to final payment</description>
        <field>Payment_Type__c</field>
        <literalValue>Final Payment</literalValue>
        <name>Set Payment Type to Final Payment</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Deposit Payment Created</fullName>
        <actions>
            <name>Set_Payment_Type_to_Deposit</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>Fires any time a payment is created and is linked to an order and the revenue recognition date is not filled in</description>
        <formula>AND(
ISBLANK( Order__r.Revenue_Recognized_Date__c ),
NOT(ISBLANK( Order__c))
)</formula>
        <triggerType>onCreateOnly</triggerType>
    </rules>
    <rules>
        <fullName>Final Payment Created</fullName>
        <actions>
            <name>Set_Payment_Type_to_Final_Payment</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>Fires any time a payment is created and is linked to an order and the revenue recognition date is  filled in</description>
        <formula>AND(
NOT(ISBLANK( Order__r.Revenue_Recognized_Date__c )),
NOT(ISBLANK( Order__c))
)</formula>
        <triggerType>onCreateOnly</triggerType>
    </rules>
</Workflow>
