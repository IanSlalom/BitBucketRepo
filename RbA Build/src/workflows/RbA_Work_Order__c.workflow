<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>Last_Renovate_Right_Date_Notification</fullName>
        <description>Last Renovate Right Date Notification</description>
        <protected>false</protected>
        <recipients>
            <type>owner</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>RbA_Email_Templates/LastRenovateRightDateNotification</template>
    </alerts>
    <alerts>
        <fullName>PaintStainVendorFollowUp</fullName>
        <description>PaintStainVendorFollowUp</description>
        <protected>false</protected>
        <recipients>
            <type>owner</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>RbA_Email_Templates/PaintStainInstallReminder</template>
    </alerts>
    <fieldUpdates>
        <fullName>Set_Completed_Date_Install</fullName>
        <field>Completed_Appt_Date_Install__c</field>
        <formula>Today()</formula>
        <name>Set Completed Date - Install</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Completed_Date_Service</fullName>
        <field>Completed_Appt_Date_Service__c</field>
        <formula>Today()</formula>
        <name>Set Completed Date - Service</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Completed_Date_Tech_Measure</fullName>
        <field>Completed_Appt_Date_Tech_Measure__c</field>
        <formula>Today()</formula>
        <name>Set Completed Date - Tech Measure</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Last Renovate Right Date Notification</fullName>
        <actions>
            <name>Last_Renovate_Right_Date_Notification</name>
            <type>Alert</type>
        </actions>
        <active>false</active>
        <criteriaItems>
            <field>RbA_Work_Order__c.Age__c</field>
            <operation>greaterThan</operation>
            <value>53</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>PaintStainInstallReminder</fullName>
        <active>true</active>
        <criteriaItems>
            <field>RbA_Work_Order__c.Work_Order_Type__c</field>
            <operation>equals</operation>
            <value>Paint/Stain</value>
        </criteriaItems>
        <criteriaItems>
            <field>RbA_Work_Order__c.Work_Order_Status__c</field>
            <operation>notEqual</operation>
            <value>Closed,Cancelled</value>
        </criteriaItems>
        <description>Reminder to the Work Order Owner to follow up with the Paint Stain Vendor.</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
        <workflowTimeTriggers>
            <actions>
                <name>PaintStainVendorFollowUp</name>
                <type>Alert</type>
            </actions>
            <offsetFromField>RbA_Work_Order__c.Scheduled_Installation_Date__c</offsetFromField>
            <timeLength>3</timeLength>
            <workflowTimeTriggerUnit>Days</workflowTimeTriggerUnit>
        </workflowTimeTriggers>
    </rules>
    <rules>
        <fullName>Set Install WO Completed Date</fullName>
        <actions>
            <name>Set_Completed_Date_Install</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>RbA_Work_Order__c.Work_Order_Type__c</field>
            <operation>equals</operation>
            <value>Install</value>
        </criteriaItems>
        <criteriaItems>
            <field>RbA_Work_Order__c.Work_Order_Scheduling_Status__c</field>
            <operation>equals</operation>
            <value>Complete</value>
        </criteriaItems>
        <description>When the appoitment has been completed and work order has been closed this will update Completed Appt Date/Time: Install</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Set Service WO Completed Date</fullName>
        <actions>
            <name>Set_Completed_Date_Service</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>RbA_Work_Order__c.Work_Order_Type__c</field>
            <operation>equals</operation>
            <value>Service</value>
        </criteriaItems>
        <criteriaItems>
            <field>RbA_Work_Order__c.Work_Order_Scheduling_Status__c</field>
            <operation>equals</operation>
            <value>Complete</value>
        </criteriaItems>
        <description>When the appoitment has been completed and work order has been closed this will update Completed Appt Date/Time: Service</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Set Tech Measure WO Completed Date</fullName>
        <actions>
            <name>Set_Completed_Date_Tech_Measure</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>RbA_Work_Order__c.Work_Order_Type__c</field>
            <operation>equals</operation>
            <value>Tech Measure</value>
        </criteriaItems>
        <criteriaItems>
            <field>RbA_Work_Order__c.Work_Order_Scheduling_Status__c</field>
            <operation>equals</operation>
            <value>Complete</value>
        </criteriaItems>
        <description>When the appoitment has been completed and work order has been closed this will update Completed Appt Date/Time: Tech Measure</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
</Workflow>
