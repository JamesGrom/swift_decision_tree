//
//  ViewController.swift
//  decisionTree
//
//  Created by James Grom on 6/13/21.
//
import UIKit
//attributeType = type of the attribute on which the node sorts its children on
//valueType = type of the potential values the given attribute can take
//resultType = type of the result the decision tree will return (eg INT for 1||0 , String for "Male"||"Femle" etc)
//resultKey, should be static throught nodes, key used to access the result value from an instance
class templatizedNode <attributeType: Hashable,valueType:Equatable,resultType:Equatable>{
    var children : [templatizedNode<attributeType,valueType,resultType>] = []
    weak var parent : templatizedNode<attributeType,valueType,resultType>?
    //attribute holds the value for which the node sorts its children on (nil for leaf nodes)
    var attribute: attributeType?
    //value holds the value of the node (nil for parent nodes)
    var value: resultType?
    //key used to access the result value from an instance
    var resultKey: attributeType
    //instances holds array of dictionaries, where each dictionary holds an instance state
    //attributeTypes are casted to strings such that they're hashable when accessing instances
    var instances: [[attributeType:valueType]] = []
    
    //setup initializers
    init(attributeSortedOn: attributeType , accessibleInstances: [[attributeType:valueType]] , givenResultKey: attributeType ) {
        //initialize the result key (should be consistent thru all nodes)
        self.resultKey = givenResultKey
        //first test if the node should be a leaf node
        // leafnode if all instances have the same result value
        var consistentResults = true
        var tempResult: resultType?
        for dictionary in accessibleInstances {
            if tempResult == nil {
                //first result encountered, initialize tempresult
                tempResult = dictionary[resultKey] as? resultType
            }
            if tempResult != dictionary[resultKey] as? resultType {
                consistentResults = false
                break
            }
        }
        //if results are consistent, initialize a leaf node
        if consistentResults {
            //initialize leaf node
            self.value = tempResult
        }else{
            //initialize a parent node
            self.attribute = attributeSortedOn
        }
        self.instances = accessibleInstances
    }
    
    //returns instances where Node's attribute has specified value , nil if empty
    func findInstances(withAttributeEqualTo: valueType) -> [[attributeType:valueType]]? {
        //if current node is a leaf just return
        if let _ = value {
            return nil
        }
        //current node is parent node
        var relevantInstances : [[attributeType:valueType]]?
        //add relevant dictionaries
        for dictionary in instances{
            if dictionary[attribute!] == withAttributeEqualTo{
                if relevantInstances == nil {
                    //add the first dictionary as needed
                    relevantInstances = [dictionary]
                }else{
                    relevantInstances!.append(dictionary)
                }
            }
        }
        return relevantInstances
    }
    
    //add child node to the current node
    func addChild(node: templatizedNode){
        self.children.append(node)
        node.parent = self
    }
}



class Node{
    // each node is either an attribute node (wherin attribute = string defining the category) || a classification node (either positive or negative)
    // a classification node has a null attribute and an attribute node has a null classification value
    var attribute: String?
    var classification : Bool?
    var instances : [[String:Int]] = []
    var posBranchNode : Node?
    var negBranchNode : Node?
    var children: [Node] = []
    //constructor for the node class
    init (attribute: String){
        self.attribute = attribute
    }
    init(classification: Bool) {
        self.classification = classification
    }
    func printNode(){
        if let attribute = attribute {
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
//                    while(i<8){
//                        //initialize H0-H7 with nil
//                        let tempKey = "H" + String(i)
//                        temp[tempKey] = 0
//                        i = i+1
//                    }
                    //14 possibilities for weight classifications
                    i = 0;
//                    while(i<14){
//                        //initialize W0-W13 with nil
//                        let tempKey = "W" + String(i)
//                        temp[tempKey] = 0
//                        i = i+1
//                    }
                    //8 possibilities for BMI classifications
                    i = 0;
//                    while(i<8){
//                        let tempKey = "BMI" + String(i)
//                        temp[tempKey] = 0
//                        i = i+1
//                    }
                    //5 possibilities for fitness index
                    i = 1;
//                    while(i<6){
//                        let tempKey = "I" + String(i)
//                        temp[tempKey] = 0
//                        i = i + 1
//                    }

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
//                            let tempKey = "H" + String(i)
//                            temp[tempKey] = 1
                            temp["Height"] = i
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
//                            let tempKey = "W" + String(i)
//                            temp[tempKey] = 1
                            temp["Weight"] = i
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
//                            let tempKey = "BMI" + String(i)
//                            temp[tempKey] = 1
                            temp["BMI"] = i
                            break
                        }
                        i = i+1
                        cutoff = cutoff + 5
                    }
                    
                    //set the fitnessIndex state
                    temp["Fitness"] = fitnessIndex
                    // DEPRICATED: temp [String:Int?] holds the 1 hot encoded values for the current row
                    //add current row into processedValues
                    processedValues.append(temp)
                }
            }
            
//            print(csv.namedRows)
//            print(parsedValues)
            print(processedValues)
        } catch{
            print("catchblock triggered")
            return
        }
        // DEPRICATED: at this point, processedValues should have 1 hot encoded list of data such that ID3 can be performed
        
        // processed values now holds the processed [String:Int] dictionaries modeling each instance
        
        //now generate training set from first 400 instances, and test set from last 100 instances
        //leading to an 80:20 split
        var testValues : [[String:Int]] = []
        var trainingValues : [[String:Int]] = []
        var i = 0
        //add 400 instances to the testValues
        while (i < 400){
            //fetch 400 of the processed instances to initialize the test values
            trainingValues.append(processedValues[i])
            i = i + 1
        }
        i = 400
        while( i < 500 ){
            testValues.append(processedValues[i])
            i = i + 1
        }
        
        //fabricate a placeholder templetized node
//        var teplatizationNode
        var tempNode : templatizedNode<String,Int,Int>?
        
        //generate the decision tree using the training values set
//        generateDecisionTree(inputDictionaries: trainingValues)
        
        
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
        let setSize = Double( currentInstances.count)
        var sum : Double = 0.0
        var attributeStates : [Int] = []
        //for each possible value the attribute may assume
        for dictionary in currentInstances {
            if let currentAttributeState = dictionary[attributeName] {
                if !attributeStates.contains(currentAttributeState){
                    //add the attribute state to the seen attributeStates
                    attributeStates.append(currentAttributeState)
                    //  generate the set where the attribute assumes the value
                    let currentSubset = findInstancesOfAttributeState(attributeName: attributeName, attributeState: currentAttributeState, currentInstances: currentInstances)
                    //compute the entropy on the set
                    let tempEntropy = findEntropy(currentInstances: currentSubset)
                    //      compute the size of the set
                    let tempSetSize = currentSubset.count
                    //      perform subsetSize / setSize * subsetEntropy
                    //      add to sum
                    sum = sum + ((Double(tempSetSize) / setSize)*tempEntropy)
                }
            }
        }
        //return the gain
        return setEntropy - sum
//
//        let posSubset = findInstancesOfAttributeState(attributeName: attributeName, attributeState: 1, currentInstances: currentInstances)
//        let negSubset = findInstancesOfAttributeState(attributeName: attributeName, attributeState: 0, currentInstances: currentInstances)
//        //assumption is that given attribute has only 2 possible values due to 1 hot encoding
//        let posEntropy = findEntropy(currentInstances: posSubset)
//        let posSubsetSize = Double(posSubset.count)
//        let negEntropy = findEntropy(currentInstances: negSubset)
//        let negSubsetSize = Double(negSubset.count)
//
//        //perform the summation
//        var summation = posSubsetSize / setSize * posEntropy
//        summation = summation + negSubsetSize / setSize * negEntropy
//        return setEntropy - summation
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

    func generateDecisionTree(inputDictionaries:[[String:Int]]) -> Node {
        let returnNode = Node(attribute: "emptyNode")
        //first, find best attribute to sort on (the one with the highest gain)
        
        //generate subset for each possible value of best attribute
        
        //for each subset, if the entropy of the set == 0 (created node has all + or all - examples), fabricate a corresponding classification node, else fabricate a node for the subset by generatingDecision tree on the subset
        
        
        
        return returnNode
        
    }
    
    
    func genDecisionTree(inputInstances: [[String:Int]]) -> templatizedNode<String, Int, Int>? {
        //first, find best attribute to sort on (the one with the highest gain)
        var bestAttribute = ""
        var bestGain : Double = 0.0
        var attributeList : [String] = []
        if let temp = inputInstances.first {
            for (key,_) in temp {
                if key != "Result" && !attributeList.contains(key) {
                    attributeList.append(key)
                }
            }
        }
        
        for attribute in attributeList {
            let currentGain = findAttributeGain(attributeName: attribute, currentInstances: inputInstances)
            if(currentGain > bestGain){
                bestGain = currentGain
                bestAttribute = attribute
            }
        }
        //bestAttribute should now be the node to generate
        let currentNode = templatizedNode<String, Int, Int>(attributeSortedOn: bestAttribute, accessibleInstances: inputInstances, givenResultKey: "Result")
        //generate subset for each possible value of best attribute
        var possibleValues : [Int] = []
        for dictionary in inputInstances{
            if let temp = dictionary[bestAttribute]{
                if !possibleValues.contains(temp){
                    possibleValues.append(temp)
                }
            }
        }
        //possible values of the attribute sorted on are stored in possible values
        for value in possibleValues {
            //generate subset for each possible value in possibleValue
            if let temp = currentNode.findInstances(withAttributeEqualTo: value){
                //for each subset, if the entropy of the set == 0 (created node has all + or all - examples), fabricate a corresponding classification node, else fabricate a node for the subset by generatingDecision tree on the subset
                if findEntropy(currentInstances: temp) == 0 {
                    //generate a leaf node and link as child
                    let tmp = templatizedNode<String, Int, Int>(attributeSortedOn: bestAttribute, accessibleInstances: temp, givenResultKey: "Result")
                    //leafNode can be immediately added to the tree
                    currentNode.addChild(node: tmp)
                }else{
                    if let tmp = genDecisionTree(inputInstances: temp) {
                        currentNode.addChild(node: tmp)
                    }
                }
            }
            
            
            
        }
        
        return nil
    }
    
  
}

