//
//  File.swift
//  Onelook Search
//
//  Created by Pyokyeong Son on 2020/06/11.
//  Copyright © 2020 Pyokyeong Son. All rights reserved.
//

import Foundation

/// structure to hold the returned json array
internal struct WordData: Decodable {
    // part that makes it adhere to Decodable protocol
    enum Category: String, Decodable {
        case swift, combine, debugging, xcode
    }
    
    let word: String
    let score: Int?
    
    let numSyllables: Int?
    let defs: [String]?
    let tags: [String]? // contains the part of speech, pronounciation and word frequency info
}

/// Class holding static functions that return the formatted word data from OneLook APIs

class Search {

    // The types of searches available in the OneLook API, e.g. synonyms, antonyms, homophones, etc.
    enum SearchType: String {
        case soundLike = "sl"
        case meanLike = "ml"
        case spelledLike = "sp"
        case topics = "topics"
        case searchSpace = "v"
        case max = "max"
        
        // Related query keys
        case nounsModifiedBy = "rel_jja"
        case adjectivesModifying = "rel_jjb"
        case synonymsOf = "rel_syn"
        case triggers = "rel_trg"
        case antonymsOf = "rel_ant"
        case kindOfLike = "rel_spc"
        case moreGeneralThan = "rel_gen"
        case comprises = "rel_com"
        case isPartOf = "rel_par"
        case follows = "rel_bga"
        case preceeds = "rel_bgb"
        case rhymesPerfectlyWith = "rel_rhy"
        case rhymesAlmostWith = "rel_nry"
        case homophonesOf = "rel_hom"
        case consonantMatches = "rel_cns"
        
        // Words on the left or right
        case left = "lc"
        case right = "rc"
        
        case metadata = "md"
    }
    
    // The search space of the OneLook API
    enum SearchSpace: String {
        case spanishBooks = "es" // 500,000-term vocabulary of words from Spanish-language books
        case englishWikipedia = "enwiki" // approximately 6 million-term vocabulary of article titles from the English-language Wikipedia, updated monthly
    }
    
    private var metadataString : String
    private var options :  Dictionary<SearchType, [String]>
    
    init() {
        options = Dictionary<SearchType, [String]>()
        metadataString = ""
    }
    
    
    public func soundsLike(_ word : String) {
        options.updateValue([word], forKey: .soundLike)
    }
    
    public func meansLike(_ word : String) {
        options.updateValue([word], forKey: .meanLike)
    }
    
    public func spelledLike(_ word : String) {
        options.updateValue([word], forKey: .spelledLike)
    }
    
    public func topics(_ topics : [String]) {
        options.updateValue(topics, forKey: .topics)
    }
    
    public func related(_ code :  SearchType, _ word : String) {
        options.updateValue([word], forKey: code)
    }
    
    public func searchSpace(_ space : SearchSpace) {
        options.updateValue([space.rawValue], forKey: .searchSpace)
    }
    
    public func maxResults(_ max :  Int) {
        options.updateValue([String(max)], forKey: .max)
    }
    
    public func wordOnThe(_ side : SearchType, is word : String) {
        options.updateValue([word], forKey: side)
    }
    
    public func withDefinitions() {
        metadataString += "d"
    }
    public func withPartsOfSpeech() {
        metadataString += "p"
        
    }
    public func withSyllableCount() {
        metadataString += "s"

    }
    public func withPronounciation() {
        metadataString += "r"

    }
    public func withWordFrequency() {
        metadataString += "f"
    }
    
    public func search(_ completionHandler : @escaping ([WordData]?) -> ()) {
        // add the metadata flags into the options
        options.updateValue([metadataString], forKey: .metadata)
        
        print(options)
        Search.getData(options: options) { json in
            // Once gotten, format the data into the WordData format
            let formatted = Search.formatData(jsonString: json)
            completionHandler(formatted)
        }
    }
    
    /// Functino to get json data from OneLook
    /// - Parameters:
    ///   - word: word to search for
    ///   - parameter: type of serach request, e.g. synonyms, homphones
    ///   - completionHandler:
    /// - Returns: nothing, see completionhandler
    private static func getData(options: Dictionary<SearchType, [String]>,  _ completionHandler : @escaping (String) -> ()) {
        
        // construct url for request from words and parameters
        let url = urlConstructor(options: options)
        
        // Create the URL Session task for getting the json data
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                return
            }
            guard let httpResponse = response as? HTTPURLResponse,
                (200...299).contains(httpResponse.statusCode) else {
                    return
            }
            if let data = data {
                if let string = String(data: data, encoding: .utf8) {
                    completionHandler(string)
                }
            }
        }
        task.resume()
    }
    

    /// takes search options, and return the api's URL
    /// - Parameter options: <#options description#>
    private static func urlConstructor (options: Dictionary<SearchType, [String]>) -> URL {
        var scheme = ""
        options.forEach { pair in
            scheme += (
                pair.key.rawValue
                    + "="
                    + (pair.key == SearchType.topics ? pair.value.joined(separator: ",") : pair.value.joined() ) // topics need to be joined by "," and metadata must be joined without delimiters
                    + "&"
            )
        }
        print(scheme)
        return URL(string: "https://api.datamuse.com" + "/words?" + scheme)!
    }
    
    /// Formats the json data to WordData format
    /// - Parameter jsonString: the pure string of json
    /// - Returns: an array of WordDatas extracted from json
    private static func formatData(jsonString: String) -> [WordData]? {
        let jsonData = jsonString.data(using: .utf8)!
        do {
            let data = try JSONDecoder().decode([WordData].self, from: jsonData)
            return data;
        } catch let DecodingError.dataCorrupted(context) {
            print(context)
        } catch let DecodingError.keyNotFound(key, context) {
            print("Key '\(key)' not found:", context.debugDescription)
            print("codingPath:", context.codingPath)
        } catch let DecodingError.valueNotFound(value, context) {
            print("Value '\(value)' not found:", context.debugDescription)
            print("codingPath:", context.codingPath)
        } catch let DecodingError.typeMismatch(type, context)  {
            print("Type '\(type)' mismatch:", context.debugDescription)
            print("codingPath:", context.codingPath)
        } catch {
            print("error: ", error)
        }
        return nil
    }
    
}
