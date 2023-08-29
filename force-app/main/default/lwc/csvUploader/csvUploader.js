import {LightningElement,track,api} from 'lwc';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import getSObjects from '@salesforce/apex/AuraEnabledUtilities.getSObjects';
import dbUpdate from '@salesforce/apex/AuraEnabledUtilities.dbUpdate';
import dbInsert from '@salesforce/apex/AuraEnabledUtilities.dbInsert';
import getFields from '@salesforce/apex/AuraEnabledUtilities.getFields';
import getSavedMDMappings from '@salesforce/apex/csvUploaderHelper.getSavedMDMappings';
import dbUpdateWExternalKey from '@salesforce/apex/AuraEnabledUtilities.dbUpdateWExternalKey';
import dbBatchDML from '@salesforce/apex/csvUploaderHelper.dbBatchDML';
import dbUpsert from '@salesforce/apex/AuraEnabledUtilities.dbUpsert';
import dbBatchUpdateWExternalKey from '@salesforce/apex/csvUploaderHelper.dbBatchUpdateWExternalKey';
import { reduceErrors } from 'c/ldsUtils';

export default class CsvUploader extends LightningElement {

    @track data;
    @track fileName = '';
    @track UploadFile = 'Upload CSV File';
    @track showLoadingSpinner = false;
    @track showObjList=false;
    @track showMappingTable=false;
    @track savedMappingsOptions=[];
    @track showSavedMappings=false;
    @track disableDMLButton=true;
    @track allObjects=[];
    @track mappingData=[];
    @track disableUpload=true;
    @track helpTxt='';
    @api defaultMapping;
    @api banner = 'CSV Uploader';
    headers=[];
    filedata;
    objectAPIName;
    objectFields;
    fieldsOptions;
    savedMappings;
    settings;
    mapping;
    @track templateURL;

    
    connectedCallback(){
        this.getSavedMappings();
        //this.setupObjectPicklist();
    }
    setSavedMapping(event){
        var selected = event.detail.value;
        console.log(selected);
        for(var i=0;i<this.savedMappings.length;i++){
            console.log(this.savedMappings[i]);
            console.log(this.savedMappings[i].DeveloperName);
            if(this.savedMappings[i].DeveloperName == selected){
                this.settings=this.savedMappings[i];
                this.templateURL=this.settings.Template_Url__c;
                break;
            }
        }
        this.disableUpload=false;
    }
    getSavedMappings(){
        getSavedMDMappings()
            .then(result => {
                console.log(result);
                this.savedMappings = result;
                for(var i=0;i<result.length;i++){
                    let item = {value:(result[i].DeveloperName),label:(result[i].MasterLabel)};
                    this.savedMappingsOptions.push(item);
                    console.log(item);
                }
                //let item = {value:'New',label:'New'};
                //this.savedMappingsOptions.push(item);
                
                if(this.defaultMapping!=null){
                    var obj={detail:{value:this.defaultMapping}};
                    this.setSavedMapping(obj);
                }else{
                    this.showSavedMappings=true;
                }
            })
            .catch(error => {
                console.log(error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error Loading Saved Mappings',
                        message: error.message,
                        variant: 'error',
                    }),
                );
            });
    }
    
    async handleFilesChange(event) {
        if (event.target.files.length > 0) {
            this.showLoadingSpinner=true;
            this.headers= new Array();
            this.fileName = event.target.files[0].name;
            this.filedata = await this.readFileAsync(event.target.files[0]);
            var headerEnd = this.filedata.search(/(?:\r\n|\r|\n)/g);
            var temp = this.filedata.substring(0,headerEnd);
            var temp1=temp.split(',');
            temp1.forEach(obj => {
                obj = obj.replaceAll('\"','');
                obj = obj.trim();
                this.headers.push(obj);
            })
            this.buildsObjects();
            this.showLoadingSpinner=false;
        }
    }
    readFileAsync(file) {
        return new Promise((resolve, reject) => {
          let reader = new FileReader();
      
          reader.onload = () => {
            resolve(reader.result);
          };
      
          reader.onerror = reject;
      
          reader.readAsText(file);
        })
    }
    
    buildsObjects(){
        this.showLoadingSpinner = true;
        this.disableDMLButton=true;
        var sObjectList = [];
        var lines = this.filedata.split(/(?:\r\n|\r|\n)/g);
        lines=lines.splice(1,lines.length-2);
        lines.forEach(element => {
            let record = { 'sobjectType': this.settings.ObjectAPI__c };
            var vals = element.split(/,(?=(?:(?:[^"]*"){2})*[^"]*$)/);
            //console.log(vals,'vals');
            var map =JSON.parse((this.settings.Mapping__c).valueOf());
            for(var i=0;i<vals.length;i++){
                for(var j= 0;j<map.length;j++){
                    //console.log(map[j].header,this.headers[i]);
                    if(map[j].header==this.headers[i]){
                        record[map[j].fieldAPI]=vals[i].replaceAll('\"','');
                        //console.log(vals[i],record[map[j].fieldAPI]);
                        map.splice(j, 1);
                        break;
                    }
                }
                /*var fieldMapping =this.mapping.filter(obj => {
                    console.log(obj.header,this.headers[i]);
                    return this.headers[i]==(obj.header);
                });
                if(fieldMapping[0])record[fieldMapping[0].fieldAPI]=vals[i];*/
            }
            sObjectList.push(record);
        });
        this.data = [...sObjectList];
        if(this.data.length>0){
            this.disableDMLButton=false;
        }
        console.log(this.data.length,' Record Count');
        console.log(sObjectList);        
        return sObjectList;
    }
    handleDML(){
        if(this.settings.DML_Type__c=='Insert'){
            this.handleInsert();
        }else if(this.settings.DML_Type__c=='Update'){
            this.handleUpdate();
        }else if(this.settings.DML_Type__c=='Upsert'){
            this.handleUpsert();
        }else if(this.settings.DML_Type__c=='Delete'){
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error Delete Not Yet Supported',
                    message: '',
                    variant: 'error',
                }),
            );
        }
        this.data=null;
    }

    handleUpsert(){
        if(this.data.length>this.settings.Synchronous_Limit__c){
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error Asynchronous Upsert  Not Yet Supported retry with less than '+this.data.length+' records',
                    message: '',
                    variant: 'error',
                }),
            );
        }
        this.showLoadingSpinner = true;
        this.disableDMLButton=true;
        dbUpsert({sObjects: this.data,
            fieldAPI: this.settings.ExternalIdFieldAPI__c,
            objectAPI:this.settings.ObjectAPI__c,
            otherApexClassName:this.settings.ApexClass__c,
            otherApexMethodName:this.settings.ApexMethod__c})
            .then(result => {this.successfullUpload(result);})
            .catch(error => {this.failedUpload(error);});
    }

    handleInsert(){
        if(this.data.length>this.settings.Synchronous_Limit__c){
            this.asyncBatchDML('insert');
            return null;
        }
        this.showLoadingSpinner = true;
        this.disableDMLButton=true;
        dbInsert({sObjects: this.data})
            .then(result => {this.successfullUpload(result);})
            .catch(error => {this.failedUpload(error);});
    }
    handleUdpateWExternalKey(){
        var callApex=false;
        if(this.settings.ApexClass__c!=null)callApex=true;
        if(this.data.length>this.settings.Synchronous_Limit__c){
            this.showLoadingSpinner = true;
            this.disableDMLButton=true;
            console.log(this.data.length);
            var callApex=false;
            if(this.settings.ApexClass__c!=null)callApex=true;
            dbBatchUpdateWExternalKey({sObjects: this.data,
                fieldAPI: (this.settings.ExternalIdFieldAPI__c),
                objectAPI:(this.settings.ObjectAPI__c),
                onBatchCompletionCallOtherApex:callApex,
                otherApexClassName:this.settings.ApexClass__c,
                otherApexMethodName:this.settings.ApexMethod__c})
                .then(result => {this.asyncScheduledSuccess(result);})
                .catch(error => {this.asyncScheduledFailed(error);});
        }else{
            this.showLoadingSpinner = true;
            this.disableDMLButton=true;
            dbUpdateWExternalKey({sObjects: this.data,
                fieldAPI: this.settings.ExternalIdFieldAPI__c,
                objectAPI:this.settings.ObjectAPI__c,
                onBatchCompletionCallOtherApex:callApex,
                otherApexClassName:this.settings.ApexClass__c,
                otherApexMethodName:this.settings.ApexMethod__c})
                .then(result => {this.successfullUpload(result);})
                .catch(error => {this.failedUpload(error);});
        }
    }
    handleUpdate(){
        if(this.settings.ExternalIdFieldAPI__c!=null){
            this.handleUdpateWExternalKey();
        }else{
            if(this.data.length>this.settings.Synchronous_Limit__c){
                this.asyncBatchDML('update');
                return null;
            }
            this.showLoadingSpinner = true;
            this.disableDMLButton=true;
            dbUpdate({sObjects: this.data})
                .then(result => {this.successfullUpload(result);})
                .catch(error => {this.failedUpload(error);});
        }
        
    }

    asyncBatchDML(Type){
        this.showLoadingSpinner = true;
        this.disableDMLButton=true;
        dbBatchDML({sObjects: this.data,dmlType:Type})
                .then(result => {this.asyncScheduledSuccess(result);})
                .catch(error => {this.asyncScheduledFailed(error);});
    }

    asyncScheduledSuccess(result){
        console.log(result);
        this.showLoadingSpinner = false;
        this.dispatchEvent(
            new ShowToastEvent({title: 'Success!!',message: 'Upload Scheduled Successfully!!!',variant: 'success',
            }),
        );
    }
    asyncScheduledFailed(error){
        console.log(error);
        this.showLoadingSpinner = false;
        var errorMSG = reduceErrors(error);
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error while Scheduling Upload',
                message: errorMSG.join('\n'),
                variant: 'error',
            }),
        );
    }
    successfullUpload(result){
        console.log(result);
        this.fileName = this.fileName + ' - Uploaded Successfully';
        this.showLoadingSpinner = false;
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success!!',
                message: result,
                variant: 'success',
            }),
        );
    }
    failedUpload(error){
        console.log(error);
        this.showLoadingSpinner = false;
        var errorMSG = reduceErrors(error);
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error while uploading File',
                message: errorMSG.join('\n'),
                variant: 'error',
            }),
        );
    }


//Future Feautres
    buildMappingTable(){
        this.showMappingTable=true;
        this.headers.forEach(header =>{
            var line = {ObjectField:'',header: header};
            this.mappingData.push(line);
        });
    }
    setupObjectPicklist(){
        this.showObjList=false;
        getSObjects()
            .then(result => {
                this.allObjects = result;
                console.log(this.allObjects);
                this.showObjList=true;
            })
            .catch(error => {
                console.log(error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error Loading Objects',
                        message: error.message,
                        variant: 'error',
                    }),
                );
            });
    }
    handleObjectChange(event){
        this.showLoadingSpinner = true;
        this.settings.ObjectAPI__c = event.detail.value
        console.log(event.detail.value);
        
        getFields({objectAPIName: this.settings.ObjectAPI__c})
            .then(result => {
               console.log(result);
               this.objectFields=result;
               this.fieldsOptions=result;
               this.showLoadingSpinner = false;
               
            })
            .catch(error => {
                this.failedUpload(error);
            });
    }

    

}