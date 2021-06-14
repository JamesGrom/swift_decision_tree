//
//  ViewController.swift
//  decisionTree
//
//  Created by James Grom on 6/13/21.
//

import UIKit
class Node<Type>{
    // each node is either an attribute node (wherin attribute = string defining the category) || a classification node (either positive or negative)
    // a classification node has a null attribute and an attribute node has a null classification value
    var attribute: Type?
    var classification : Bool?
    var instances : [[String:Int]] = []
    var children: [Node] = []
    //constructor for the node class
    init (attribute: Type){
        self.attribute = attribute
    }
    init(classification: Bool) {
        self.classification = classification
    }
    func printNode(){
        if let attribute = attribute as? String {
            print(attribute)
        }
        if let classification = classification {
            print(classification)
        }
    }
    func add(_ child: Node){
        self.children.append(child)
    }
}

class ViewController: UIViewController {

    var parsedValues: [[String:String]] = []
    var processedValues: [[String:Int]] = []
    override func viewDidLoad() {
        super.viewDidLoad()
        do {
            let fileURL = Bundle.main.url(forResource: "dataset", withExtension: ".csv")!
            let csv: CSV = try CSV(url: fileURL)
            print(csv)
            print(csv.namedRows)
//            var i = 0;
            for (_,var row) in csv.namedRows.enumerated() {
                //each row is a dictionary, add the corresponding BMI value to the dictionary
                if var heightVal = Float(row["Height"] ?? "0.0"), var weightVal = Float(row["Weight"] ?? "0.0"), var genderState = row["Gender"]{
                    print("height = " , heightVal)
                    print("weight = " , weightVal)
                    //initialize the BMI value
                    weightVal = weightVal * 10000
                    heightVal = heightVal * heightVal
                    let bmiVal = weightVal / heightVal
                    let bmiString = String(bmiVal)
                    // add the BMI feild to the corresponding csv row
                    row["BMI"] = bmiString
                    //update the Gender field
                    row.removeValue(forKey: "Gender")
                    if genderState == "Male" {
                        genderState = "True"
                    }else{
                        genderState = "False"
                    }
                    row["Result"] = genderState
                    parsedValues.append(row)
                }
            }
            
            //fabricate the processed values from the parsed values
            for row in parsedValues {
                if let heightVal = Float(row["Height"] ?? "0.0"), let weightVal = Float(row["Weight"] ?? "0.0"), let resultState = row["Result"] , let fitnessIndex = Int(row["Index"] ?? "-1"), let bmiVal = Float(row["BMI"] ?? "0.0") {
                    //initialize OneHot encoding for parsed values
                    var temp : [String:Int] = [:]
                    //8 possibilities for height classifications
                    var i = 0;
                    while(i<8){
                        //initialize H0-H7 with nil
                        let tempKey = "H" + String(i)
                        temp[tempKey] = 0
                        i = i+1
                    }
                    //14 possibilities for weight classifications
                    i = 0;
                    while(i<14){
                        //initialize W0-W13 with nil
                        let tempKey = "W" + String(i)
                        temp[tempKey] = 0
                        i = i+1
                    }
                    //8 possibilities for BMI classifications
                    i = 0;
                    while(i<8){
                        let tempKey = "BMI" + String(i)
                        temp[tempKey] = 0
                        i = i+1
                    }
                    //5 possibilities for fitness index
                    i = 1;
                    while(i<6){
                        let tempKey = "I" + String(i)
                        temp[tempKey] = 0
                        i = i + 1
                    }

                    //set the Result state
                    if(resultState == "Male"){
                        temp["Result"] = 1
                    }else{
                        temp["Result"] = 0
                    }
                    
                    //set the height state
                    i = 0;
                    var cutoff = Float(130)
                    while(i<8){
                        if heightVal < cutoff || cutoff == 190{
                            //set the appropriate field value
                            let tempKey = "H" + String(i)
                            temp[tempKey] = 1
                            break
                        }
                        i = i+1
                        cutoff = cutoff + 10
                    }
                    //set the weight state
                    i = 0;
                    cutoff = 40
                    while(i<14){
                        if weightVal < cutoff || cutoff == 160{
                            //set the appropriate field value
                            let tempKey = "W" + String(i)
                            temp[tempKey] = 1
                            break
                        }
                        i = i+1
                        cutoff = cutoff + 10
                    }
                    //set the bmi State
                    i = 0;
                    cutoff = 10
                    while(i<8){
                        if bmiVal < cutoff || cutoff == 45{
                            //set the appropriate field value
                            let tempKey = "BMI" + String(i)
                            temp[tempKey] = 1
                            break
                        }
                        i = i+1
                        cutoff = cutoff + 5
                    }
                    
                    //set the fitnessIndex state
                    let tempKey = "I" + String(fitnessIndex)
                    temp[tempKey] = 1
                    
                    //temp [String:Int?] holds the 1 hot encoded values for the current row
                    //add current row into processedValues
                    processedValues.append(temp)
                }
            }
            
            print(csv.namedRows)
            print(parsedValues)
            print(processedValues)
        } catch{
            print("catchblock triggered")
            return
        }
        //at this point, processedValues should have 1 hot encoded list of data such that ID3 can be performed
        
    }
    
    //returns array of instances (modeled as dictionaries) for which the attribute has the given attribute state
    func findInstancesOfAttributeState(attributeName:String,attributeState: Int,currentInstances:[[String:Int]]) -> [[String:Int]]{
        var tempReturnVal : [[String:Int]] = []
        //add the appropriate instances to the return array
        for dictionary in currentInstances {
            if dictionary[attributeName] == attributeState {
                tempReturnVal.append(dictionary)
            }
        }
        return tempReturnVal
    }
    
    func findAttributeGain(attributeName:String,currentInstances:[[String:Int]])-> Double{
        //get entropy for the current set
        let setEntropy = findEntropy(currentInstances: currentInstances)
        let posSubset = findInstancesOfAttributeState(attributeName: attributeName, attributeState: 1, currentInstances: currentInstances)
        let negSubset = findInstancesOfAttributeState(attributeName: attributeName, attributeState: 0, currentInstances: currentInstances)
        //assumption is that given attribute has only 2 possible values due to 1 hot encoding
        let posEntropy = findEntropy(currentInstances: posSubset)
        let posSubsetSize = Double(posSubset.count)
        let negEntropy = findEntropy(currentInstances: negSubset)
        let negSubsetSize = Double(negSubset.count)
        let setSize = Double( currentInstances.count)
        //perform the summation
        var summation = posSubsetSize / setSize * posEntropy
        summation = summation + negSubsetSize / setSize * negEntropy
        return setEntropy - summation
    }

    
    func findEntropy(currentInstances:[[String:Int]])->Double {
        var numPos = 0.0
        var numNeg = 0.0
        for dictionary in currentInstances {
            if dictionary["Result"] == 1{
                numPos = numPos + 1
            }else{
                numNeg = numNeg + 1
            }
        }
        let pPos = numPos / (numPos + numNeg)
        let pNeg = numNeg / (numNeg + numPos)
        return -1.0 * pPos * log2(pPos) - pNeg * log2(pNeg)
    }

}

