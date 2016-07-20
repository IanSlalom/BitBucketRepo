<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>Notify_Record_Owner_Resource_to_be_Inactive</fullName>
        <description>Notify Record Owner Resource to be Inactive</description>
        <protected>false</protected>
        <recipients>
            <type>owner</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>RbA_Email_Templates/ResourceInsuranceExpiring</template>
    </alerts>
    <fieldUpdates>
        <fullName>Duplicate_Catcher_Resource_Record</fullName>
        <field>Duplicate_Value_Catcher__c</field>
        <formula>RbA_User__r.Id &amp; Text(Resource_Type__c)</formula>
        <name>Duplicate Catcher: Resource Record</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Reactivate_Resource</fullName>
        <field>Active__c</field>
        <literalValue>1</literalValue>
        <name>Reactivate Resource</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Inactive_Reason</fullName>
        <field>Inactive_Reason__c</field>
        <literalValue>Insurance Expiration</literalValue>
        <name>Set Inactive Reason</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Resource_Inactive</fullName>
        <field>Active__c</field>
        <literalValue>1</literalValue>
        <name>Set Resource Inactive</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Duplicate Catcher%3A Resource</fullName>
        <actions>
            <name>Duplicate_Catcher_Resource_Record</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>Resouce Records cannot have the same user and different resource types</description>
        <formula>TRUE</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Reactivate Resource</fullName>
        <actions>
            <name>Reactivate_Resource</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Resource__c.Active__c</field>
            <operation>equals</operation>
            <value>False</value>
        </criteriaItems>
        <criteriaItems>
            <field>Resource__c.Auto_Insurance_Expiration_Date__c</field>
            <operation>greaterThan</operation>
            <value>TODAY</value>
        </criteriaItems>
        <criteriaItems>
            <field>Resource__c.General_Insurance_Expiration_Date__c</field>
            <operation>greaterThan</operation>
            <value>TODAY</value>
        </criteriaItems>
        <criteriaItems>
            <field>Resource__c.Work_Comp_Insurance_Expiration_Date__c</field>
            <operation>greaterThan</operation>
            <value>TODAY</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Set Resource Inactive%2C Notify Owner</fullName>
        <active>true</active>
        <booleanFilter>1 OR 2 OR 3</booleanFilter>
        <criteriaItems>
            <field>Resource__c.Auto_Insurance_Expiration_Date__c</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <criteriaItems>
            <field>Resource__c.General_Insurance_Expiration_Date__c</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <criteriaItems>
            <field>Resource__c.Work_Comp_Insurance_Expiration_Date__c</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
        <workflowTimeTriggers>
            <actions>
                <name>Notify_Record_Owner_Resource_to_be_Inactive</name>
                <type>Alert</type>
            </actions>
            <offsetFromField>Resource__c.Inactive_Date__c</offsetFromField>
            <timeLength>-1</timeLength>
            <workflowTimeTriggerUnit>Days</workflowTimeTriggerUnit>
        </workflowTimeTriggers>
        <workflowTimeTriggers>
            <actions>
                <name>Set_Inactive_Reason</name>
                <type>FieldUpdate</type>
            </actions>
            <actions>
                <name>Set_Resource_Inactive</name>
                <type>FieldUpdate</type>
            </actions>
            <offsetFromField>Resource__c.Inactive_Date__c</offsetFromField>
            <timeLength>7</timeLength>
            <workflowTimeTriggerUnit>Days</workflowTimeTriggerUnit>
        </workflowTimeTriggers>
    </rules>
</Workflow>
