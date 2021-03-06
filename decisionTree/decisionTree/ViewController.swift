//
//  ViewController.swift
//  decisionTree
//
//  Created by James Grom on 6/13/21.
//
import UIKit

//list of attributes
var globalAttributeList: [String] = []
//simpleNode is a templatized node with String AttributeType, int value type , int result type
class simpleNode{
    var attributedChildren : [Int:simpleNode] = [:]
    weak var parent : simpleNode?
    var attribute : String?
    var value : Int?
    var resultKey = "Result"
    var instances: [[String:Int]] = []
    
    //empty simpleNode initializer
    init(accessibleInstances:[[String:Int]]){
        self.instances = accessibleInstances
    }
    //returns instances where Node's attribute has specified value , nil if empty
    // precondition, shouldn't be called on leaf nodes
    // node's attribute should have been initialized
    func findInstances(withAttributeEqualTo: Int) -> [[String:Int]]? {
        assert(value == nil)
        assert(attribute != nil)
        //current node is parent node
        var relevantInstances : [[String:Int]]?
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
    func addAttributedChild(node: simpleNode , attributeValue: Int){
        self.attributedChildren[attributeValue] = node
        node.parent = self
    }
}



class ViewController: UIViewController {

    var parsedValues: [[String:String]] = []
    var processedValues: [[String:Int]] = []
    override func viewDidLoad() {
        super.viewDidLoad()
       runDataset1()
        runDataset2()
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
        print("set's size = " , setSize)
        var sum : Double = 0.0
        var attributeStates : [Int] = []
        //for each possible value the attribute may assume
        for dictionary in currentInstances {
            if let currentAttributeState = dictionary[attributeName] {
                if !attributeStates.contains(currentAttributeState){
                    //add the attribute state to the seen attributeStates
                    attributeStates.append(currentAttributeState)
                }
            }
        }
        for attributeState in attributeStates {
            //  generate the set where the attribute assumes the value
            let currentSubset = findInstancesOfAttributeState(attributeName: attributeName, attributeState: attributeState, currentInstances: currentInstances)
            //compute the entropy on the set
            let tempEntropy = findEntropy(currentInstances: currentSubset)
            //      compute the size of the set
            let tempSetSize = currentSubset.count
            //      perform subsetSize / setSize * subsetEntropy
            //      add to sum
            print("sum += ", Double(tempSetSize),"/",setSize, "*",tempEntropy )
            sum = sum + ((Double(tempSetSize) / setSize)*tempEntropy)
        }
        //return the gain
        print("sum = ",sum)
        return setEntropy - sum
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
        print("pPos = ", pPos , "pNeg = ",pNeg)
        if(pPos == 0.0 || pNeg == 0.0 ){
            return 0.0
        }
        return -1.0 * pPos * log2(pPos) - pNeg * log2(pNeg)
    }
    
    func generateDecisionTree(inputInstances: [[String:Int]],usedAttributes:[String]) -> simpleNode?{
        //find attribute (not in the list of used attributes) with the highest gain
        var bestAttribute: String?
        var bestGain: Double = 0.0
        //generate list of potential atributes to sort on , only consider attributes for which this branch hasn't already been sorted on
        var attributeList: [String] = []
        for attributeString in globalAttributeList {
            if !usedAttributes.contains(attributeString){
                attributeList.append(attributeString)
            }
        }
        //attributeList now contains list of possible attributes to sort on
        //if attributeList is empty, then must return a leaf node with the value = majority of input instances
        if attributeList.count == 0 {
            let numPosInstances = findInstancesOfAttributeState(attributeName: "Result", attributeState: 1, currentInstances: inputInstances).count
            let numNegInstances = findInstancesOfAttributeState(attributeName: "Result", attributeState: 0, currentInstances: inputInstances).count
            if numPosInstances > numNegInstances {
                //return a leaf node with positive result value
                let resultNode = simpleNode(accessibleInstances: [])
                resultNode.value = 1
                return resultNode
            }else{
                let resultNode = simpleNode(accessibleInstances: [])
                resultNode.value = 0
                return resultNode
            }
        }
        
        //find the next, best attribute to sort on
        print("attributes viable to sort on",attributeList)
        for attribute in attributeList {
            let currentGain = findAttributeGain(attributeName: attribute, currentInstances: inputInstances)
            
            if currentGain >= bestGain {
                bestGain = currentGain
                bestAttribute = attribute
            }
            print("GainOf ", attribute,"= " , currentGain, "bestGain = " , bestGain)
        }
        //if a best attribute was found
        if let bestAttribute = bestAttribute {
            //update the list of used attributes to include the new attribute
            var currentUsedAttributes = usedAttributes
            currentUsedAttributes.append(bestAttribute)
            //now create a node to sort on with the best attribute
            let currentNode = simpleNode(accessibleInstances: inputInstances)
            //define the currentNode's attribute in which its children are sorted on
            currentNode.attribute = bestAttribute
            //generate subset for each possible value of best attribute
            var possibleValues : [Int] = []
            for dictionary in inputInstances{
                if let temp = dictionary[bestAttribute]{
                    if !possibleValues.contains(temp){
                        possibleValues.append(temp)
                    }
                }
            }
            //possible values of the relevant attribute are stored in possible values
            for value in possibleValues {
                //generate subset for each possible value
                if let instancesWithValue = currentNode.findInstances(withAttributeEqualTo: value) {
                    //discern if subset can generate a leaf node
                    //                //find numPositive
                    let numPositive = findInstancesOfAttributeState(attributeName: "Result", attributeState: 1, currentInstances: instancesWithValue).count
                    //                //find numNegative
                    let numNegative = findInstancesOfAttributeState(attributeName: "Result", attributeState: 0, currentInstances: instancesWithValue).count
                    if numPositive == 0 {
                        //generate a negative leaf node and append it to the currentNode
                        let leafNode = simpleNode(accessibleInstances: [])
                        leafNode.value = 0
                        currentNode.addAttributedChild(node: leafNode, attributeValue: value)
                        continue
                    }
                    if numNegative == 0 {
                        //generate a positive leaf node and append it to the currentNode
                        let leafNode = simpleNode(accessibleInstances: [])
                        leafNode.value = 1
                        currentNode.addAttributedChild(node: leafNode, attributeValue: value)
                        continue
                    }
                    // generate child node by recursively calling generateDecisionTree
                    if let childNode = generateDecisionTree(inputInstances: instancesWithValue, usedAttributes: currentUsedAttributes){
                        //add the childNode to the currentNode's children
                        currentNode.addAttributedChild(node: childNode, attributeValue: value)
                    }
                }else{
                    //handle case where attribute never assumes the current value
                    print("Error: must handle case where attribute never assumes current value")
                    assert(false)
                    return nil
                }
                
            }
            //here currentNode should be properly updated
            //return currentNode
            return currentNode
        }else{
            //handle case where no bestAttribute was found
            print("generateDecisionTree():: produced a defaulted leafNode")
            let numPosInstances = findInstancesOfAttributeState(attributeName: "Result", attributeState: 1, currentInstances: inputInstances).count
            let numNegInstances = findInstancesOfAttributeState(attributeName: "Result", attributeState: 0, currentInstances: inputInstances).count
            if numPosInstances > numNegInstances {
                //return a leaf node with positive result value
                let resultNode = simpleNode(accessibleInstances: [])
                resultNode.value = 1
                return resultNode
            }else{
                let resultNode = simpleNode(accessibleInstances: [])
                resultNode.value = 0
                return resultNode
            }
        }
    }

    //input: 
    //      -Root Node of decision tree used to predict the result
    //      -1 example (modeled by a dictionary) that contains the attribute values of the example 
    //output: 
    //      -returns the value predicted by the decision tree, given the relevant example info 
    func predictInstanceResult(instanceDictionary:[String:Int],decisionTreeNode:simpleNode) -> Int {
        //if at leaf node , return the predicted value
        if let leafValue = decisionTreeNode.value{
            return leafValue
        }else{
            //called node isn't a leaf node
            if let relevantAttribute = decisionTreeNode.attribute , let attributeValue = instanceDictionary[relevantAttribute]{
                print(relevantAttribute , " node traversed in decision tree")
                //if the node has a matching child node
                if let childNode = decisionTreeNode.attributedChildren[attributeValue]{
                    var tempDictionary = instanceDictionary
                    tempDictionary.removeValue(forKey: relevantAttribute) // no longer make a prediction based on the value
                    return predictInstanceResult(instanceDictionary: instanceDictionary, decisionTreeNode: childNode)
                }else{
                    //node doesn't have a matching child node , return value of majority of current node's instances
                    print("node doesn't have matching child node")
                    let numPositive = findInstancesOfAttributeState(attributeName: "Result", attributeState: 1, currentInstances: decisionTreeNode.instances).count
                    let numNegative = findInstancesOfAttributeState(attributeName: "Result", attributeState: 0, currentInstances: decisionTreeNode.instances).count
                    if numPositive > numNegative {
                        return 1
                    }else{
                        return 0
                    }
                }
            }else{
                //the called node doesn't have a sorting attribute
                print("predicting node isn't a leaf node nor attribute node")
                assert(false)
                return 0
            }
        }
    }

    func runDataset1(){
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
                if let heightVal = Double(row["Height"] ?? "0.0"), let weightVal = Double(row["Weight"] ?? "0.0"), let resultState = row["Result"] , let fitnessIndex = Double(row["Index"] ?? "-1"), let bmiVal = Double(row["BMI"] ?? "0.0") {
                    //initialize integer encoding for parsed values
                    var temp : [String:Int] = [:]
                    //set the Result state
                    if(resultState == "True"){
                        temp["Result"] = 1
                    }else{
                        temp["Result"] = 0
                    }
                    //set the partitions for the height values
                    var j : Double = 0.0 
                    var upperValue: Double = 145.9 // first partition upper value = 145.9
                    var partitionSize: Double = 5.9 //size of the partition = 5.9
                    var numPartitions: Double = 10.0 // number of partitions 
                    //since i is zero indexed, make sure i = numPartitions -1
                    while(j<numPartitions){
                        //if height is lower than upper value of partition || outside highest partition (only on last itteration)
                        if heightVal <= upperValue || j == numPartitions - 1 {
                            temp["Height"] = Int(j) 
                            break // need to exit loop before value reinitialized in next itteration
                        } 
                        j = j + 1
                        upperValue = upperValue + partitionSize
                    }

                    //set partitions for weight values 
                    j = 0.0 
                    upperValue = 61.0 //first partition upper value = 61.00
                    partitionSize = 11.0 //size of weight partitions are 11
                    numPartitions = 10.0 // there are 10 partitions over the weight classifier 
                    //since j is zero indexed, make sure jmax = numPartitions - 1 
                    while(j<numPartitions){
                        //if height is lower than upper value of partition || outside highest partition (only on last itteration)
                        if weightVal <= upperValue || j == numPartitions - 1 {
                            temp["Weight"] = Int(j) 
                            break // need to exit loop before value reinitialized in next itteration
                        } 
                        j = j + 1
                        upperValue = upperValue + partitionSize
                    }

                    //set partitions for fitness values 
                    j = 0.0
                    // 0-0.5 , 0.5-1.5 , 1.5 - 2.5 , 2.5-3.5 , 3.5-4.5 , 4.5-5.5 
                    upperValue = 0.5 
                    partitionSize = 1.0
                    numPartitions = 6.0 
                    while(j<numPartitions){
                        //if height is lower than upper value of partition || outside highest partition (only on last itteration)
                        if fitnessIndex <= upperValue || j == numPartitions - 1 {
                            temp["Fitness"] = Int(j) 
                            break // need to exit loop before value reinitialized in next itteration
                        } 
                        j = j + 1
                        upperValue = upperValue + partitionSize
                    } 
                    
                    //set partitions for bmi values 
                    j = 0.0 
                    upperValue = 50.0 
                    partitionSize = 2.5
                    numPartitions = 17
                    while(j<numPartitions){
                        //if height is lower than upper value of partition || outside highest partition (only on last itteration)
                        if bmiVal <= upperValue || j == numPartitions - 1 {
                            temp["BMI"] = Int(j) 
                            break // need to exit loop before value reinitialized in next itteration
                        } 
                        j = j + 1
                        upperValue = upperValue + partitionSize
                    }
                    print(temp)
                    processedValues.append(temp)
                }
            }
            
            // print(processedValues)
        } catch{
            print("catchblock triggered")
            return
        }
        // DEPRICATED: at this point, processedValues should have 1 hot encoded list of data such that ID3 can be performed
        
        // processed values now holds the processed [String:Int] dictionaries modeling each instance
        
        //now generate training set from first 400 instances, and test set from last 100 instances
        //leading to an 80:20 split
        //initialize the list of attributes for the given dataset
        globalAttributeList.append("Height")
        globalAttributeList.append("Weight")
        globalAttributeList.append("BMI")
        globalAttributeList.append("Fitness")
        var testValues : [[String:Int]] = []
        var trainingValues : [[String:Int]] = []
        processedValues.shuffle()
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
        var tempNode : simpleNode?
        
        //generate the decision tree using the training values set
        tempNode = generateDecisionTree(inputInstances: trainingValues, usedAttributes: [])

        //run the decision tree on the test values
        if let rootNode = tempNode {
            var numCorrectlyPredicted = 0;
            var numIncorrectlyPredicted = 0;
            var numPredicted = 0;
            for instance in testValues {
                let predictedVal = predictInstanceResult(instanceDictionary: instance, decisionTreeNode: rootNode)
                let actualVal = instance["Result"]
                print( "Actual = " ,actualVal!,"Predicted = ",predictedVal )
                if predictedVal == actualVal {
                    numCorrectlyPredicted = numCorrectlyPredicted + 1
                    numPredicted = numPredicted + 1
                    print("Correct!" , numCorrectlyPredicted , "/" , numPredicted , "Predicted correctly")
                }else{
                    numIncorrectlyPredicted = numIncorrectlyPredicted + 1
                    numPredicted = numPredicted + 1
                    print("Incorrect" , numCorrectlyPredicted , "/" , numPredicted , "Predicted correctly")
                }
            }
            let testResultString = String("results on test set: Accuracy = ") + String(numCorrectlyPredicted) + String(" / ") + String(numPredicted)
//            print("results on test set: Accuracy = ", numCorrectlyPredicted  , "/" , numPredicted)
            
            numPredicted = 0;
            numCorrectlyPredicted = 0;
            numIncorrectlyPredicted = 0;
            //test on training set
            for instance in trainingValues {
                let predictedVal = predictInstanceResult(instanceDictionary: instance, decisionTreeNode: rootNode)
                let actualVal = instance["Result"]
                print( "Actual = " ,actualVal!,"Predicted = ",predictedVal )
                if predictedVal == actualVal {
                    numCorrectlyPredicted = numCorrectlyPredicted + 1
                    numPredicted = numPredicted + 1
                    print("Correct!" , numCorrectlyPredicted , "/" , numPredicted , "Predicted correctly")
                }else{
                    numIncorrectlyPredicted = numIncorrectlyPredicted + 1
                    numPredicted = numPredicted + 1
                    print("Incorrect" , numCorrectlyPredicted , "/" , numPredicted , "Predicted correctly")
                }
            }
            let trainingResultString = String("results on training set: Accuracy = ") + String(numCorrectlyPredicted) + String(" / ") + String(numPredicted)
            print(testResultString)
            print(trainingResultString)
        }
    }
    
    func runDataset2(){
        var parsedValues: [[String:String]] = []
        var processedValues: [[String:Int]] = [] //values defined by appropriate grouping indeces 
        do{
            let fileURL = Bundle.main.url(forResource:"dataset2",withExtension:".csv")!;
            let csv: CSV = try CSV(url:fileURL)
            print(csv.namedRows)
            for(_,var row) in csv.namedRows.enumerated(){
                //each row is an instance, add each instance to parsedValues
                parsedValues.append(row)
            }
            //fabricate processed values from parsedValues 
            for instance in parsedValues {
                var addend: [String:Int] = [:]
                if let age = Double(instance["age"] ?? "0.0") , 
                let sex = Int(instance["sex"] ?? "0"), 
                let cp = Int(instance["cp"] ?? "0"),
                let trestbps = Double(instance["trestbps"] ?? "0.0") , 
                let chol = Double(instance["chol"] ?? "0.0"),
                let fbs = Int(instance["fbs"] ?? "0"),
                let restecg = Int(instance["restecg"] ?? "0"),
                let thalach = Double(instance["thalach"] ?? "0.0"),
                let exang = Int(instance["exang"] ?? "0"),
                let oldpeak = Double(instance["oldpeak"] ?? "0.0"),
                let Result = Int(instance["Result"] ?? "111")
                {
                    //using only 11 metrics from the dataset 

                    //first add nonPartitioned inputs 
                    addend["sex"] = sex
                    addend["cp"] = cp 
                    addend["fbs"] = fbs
                    addend["restecg"] = restecg
                    addend["exang"] = exang
                    addend["Result"] = Result
                    //modify partitioned attributes 
                    //partition age attribute
                    var j : Double = 0.0 
                    var upperValue: Double = 33.8 // first partition upper value = 145.9
                    var partitionSize: Double = 4.8 //size of the partition = 5.9
                    var numPartitions: Double = 10 // number of partitions 
                    //since i is zero indexed, make sure i = numPartitions -1
                    while(j<numPartitions){
                        //if height is lower than upper value of partition || outside highest partition (only on last itteration)
                        if age <= upperValue || j == numPartitions - 1 {
                            addend["age"] = Int(j) 
                            break // need to exit loop before value reinitialized in next itteration
                        } 
                        j = j + 1
                        upperValue = upperValue + partitionSize
                    }

                    //partition trestbps attribute
                    j = 0.0 
                    upperValue = 104.6
                    partitionSize = 10.4
                    numPartitions = 10 
                    //since i is zero indexed, make sure i = numPartitions -1
                    while(j<numPartitions){
                        //if height is lower than upper value of partition || outside highest partition (only on last itteration)
                        if trestbps <= upperValue || j == numPartitions - 1 {
                            addend["trestbps"] = Int(j) 
                            break // need to exit loop before value reinitialized in next itteration
                        } 
                        j = j + 1
                        upperValue = upperValue + partitionSize
                    }

                    //partition chol attribute
                    j = 0.0 
                    numPartitions = 8
                    upperValue = 169.8
                    partitionSize = 43.8
                    //since i is zero indexed, make sure i = numPartitions -1
                    while(j<numPartitions){
                        //if height is lower than upper value of partition || outside highest partition (only on last itteration)
                        if chol <= upperValue || j == numPartitions - 1 {
                            addend["chol"] = Int(j) 
                            break // need to exit loop before value reinitialized in next itteration
                        } 
                        j = j + 1
                        upperValue = upperValue + partitionSize
                    }

                    //partition thalach attribute 
                    j = 0.0
                    numPartitions = 10
                    upperValue = 84.10
                    partitionSize = 13.1
                    while(j<numPartitions){
                        //if height is lower than upper value of partition || outside highest partition (only on last itteration)
                        if thalach <= upperValue || j == numPartitions - 1 {
                            addend["thalach"] = Int(j) 
                            break // need to exit loop before value reinitialized in next itteration
                        } 
                        j = j + 1
                        upperValue = upperValue + partitionSize
                    }

                    //partition oldpeak attribute
                    j = 0.0 
                    numPartitions = 9
                    upperValue = 0.62
                    partitionSize = 0.62
                    while(j<numPartitions){
                        //if height is lower than upper value of partition || outside highest partition (only on last itteration)
                        if oldpeak <= upperValue || j == numPartitions - 1 {
                            addend["oldpeak"] = Int(j) 
                            break // need to exit loop before value reinitialized in next itteration
                        } 
                        j = j + 1
                        upperValue = upperValue + partitionSize
                    }
                    processedValues.append(addend)
                }
            }
            //input data has been parsed and processed, now decisionTree can be constructed 
            print(processedValues)
            //need to shuffle the values, since the results are sorted from + results to - results 
            processedValues.shuffle()
            var trainingValues : [[String:Int]] = []
            var testValues : [[String:Int]] = []
            //there are 303 available instances of data 
            print(processedValues.count)
            //construct the trainingValues from first 230 of dataset2
            var i = 0 
            while(i<230){
                trainingValues.append(processedValues[i])
                i = i + 1
            }
            //construct the testValues from last 73 of dataset2
            i = 230 
            while(i<303){
                testValues.append(processedValues[i])
                i = i + 1
            }

            //generate decision tree using training value set 
            var tempNode:simpleNode?
            //update the global attributeList
            globalAttributeList = [] //clear the attributeList from prior execution
            globalAttributeList.append("age")
            globalAttributeList.append("sex")
            globalAttributeList.append("cp")
            globalAttributeList.append("trestbps")
            globalAttributeList.append("chol")
            globalAttributeList.append("fbs")
            globalAttributeList.append("restecg")
            globalAttributeList.append("thalach")
            globalAttributeList.append("exang")
            globalAttributeList.append("oldpeak")
            tempNode = generateDecisionTree(inputInstances:trainingValues,usedAttributes:[])
            
            if let rootNode = tempNode {
            var numCorrectlyPredicted = 0;
            var numIncorrectlyPredicted = 0;
            var numPredicted = 0;
            for instance in testValues {
                let predictedVal = predictInstanceResult(instanceDictionary: instance, decisionTreeNode: rootNode)
                let actualVal = instance["Result"]
                print( "Actual = " ,actualVal!,"Predicted = ",predictedVal )
                if predictedVal == actualVal {
                    numCorrectlyPredicted = numCorrectlyPredicted + 1
                    numPredicted = numPredicted + 1
                    print("Correct!" , numCorrectlyPredicted , "/" , numPredicted , "Predicted correctly")
                }else{
                    numIncorrectlyPredicted = numIncorrectlyPredicted + 1
                    numPredicted = numPredicted + 1
                    print("Incorrect" , numCorrectlyPredicted , "/" , numPredicted , "Predicted correctly")
                }
            }
            let testResultString = String("results on test set: Accuracy = ") + String(numCorrectlyPredicted) + String(" / ") + String(numPredicted)
//            print("results on test set: Accuracy = ", numCorrectlyPredicted  , "/" , numPredicted)
            
            numPredicted = 0;
            numCorrectlyPredicted = 0;
            numIncorrectlyPredicted = 0;
            //test on training set
            for instance in trainingValues {
                let predictedVal = predictInstanceResult(instanceDictionary: instance, decisionTreeNode: rootNode)
                let actualVal = instance["Result"]
                print( "Actual = " ,actualVal!,"Predicted = ",predictedVal )
                if predictedVal == actualVal {
                    numCorrectlyPredicted = numCorrectlyPredicted + 1
                    numPredicted = numPredicted + 1
                    print("Correct!" , numCorrectlyPredicted , "/" , numPredicted , "Predicted correctly")
                }else{
                    numIncorrectlyPredicted = numIncorrectlyPredicted + 1
                    numPredicted = numPredicted + 1
                    print("Incorrect" , numCorrectlyPredicted , "/" , numPredicted , "Predicted correctly")
                }
            }
            let trainingResultString = String("results on training set: Accuracy = ") + String(numCorrectlyPredicted) + String(" / ") + String(numPredicted)
            print(testResultString)
            print(trainingResultString)
        }
        }catch{
            print("error processing dataset2")
        }
        
    }
}

