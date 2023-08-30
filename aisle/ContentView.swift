import SwiftUI

struct ContentView: View {
    @State private var phoneNumber = ""
    @State private var otp = ""
    @State private var authToken = ""
    @State private var isScreen1Complete = false
    @State private var isScreen2Complete = false
    @State private var isScreen3Complete = false
    
    var body: some View {
        if !isScreen1Complete {
            Screen1View(phoneNumber: $phoneNumber, isComplete: $isScreen1Complete)
        } else if !isScreen2Complete {
            Screen2View(otp: $otp, phoneNumber: phoneNumber, authToken: $authToken, isComplete: $isScreen2Complete)
        } else if !isScreen3Complete {
            Screen3View(authToken: authToken, isComplete: $isScreen3Complete)
        } else {
            Text("All screens completed")
        }
    }
}

struct Screen1View: View {
    @Binding var phoneNumber: String
    @Binding var isComplete: Bool
    @State private var showError = false // Added state for error message

    var body: some View {
        VStack(spacing: 20) {
            Text("Get OTP")
                .font(.title)
            
            Text("Enter Your\nPhone Number")
                .font(.headline)
                .multilineTextAlignment(.center)
            // Display error message if showError is true
            if showError {
                Text("Invalid phone number")
                    .foregroundColor(.red)
                    .padding(.bottom, 5)
            }
            HStack(spacing: 10) {
                Text("+91")
                    .font(.headline)
                
                TextField("Enter Your Phone Number", text: $phoneNumber)
                    .keyboardType(.numberPad)
            }
            .padding(.horizontal)
            
            Button(action: {
                makePhoneNumberAPI()
            }) {
                Text("Continue")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(Color.yellow)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding(.vertical, 40)
    }

    
    func makePhoneNumberAPI() {
        guard let _ = Int(phoneNumber), phoneNumber.count == 10 else {
            // Show error message and return if phone number is invalid
            showError = true
            return
        }
        guard let url = URL(string: "https://app.aisle.co/V1/users/phone_number_login") else {
            return
        }
        
        let parameters = ["number": "+91" + phoneNumber]
        print("parameters",parameters)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        print("request", request)
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted)
        } catch {
            print("JSON Serialization Error: \(error)")
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                do {
                    let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
//                    print("jsonResponse",jsonResponse)
                    if let status = jsonResponse?["status"] as? Int, status == 1 {
//                        print("inside if case")
                        // Handle successful response
                        DispatchQueue.main.async {
                            isComplete = true
                        }
                    } else {
                        // Handle unsuccessful response
                        let errorMessage = jsonResponse?["error"] as? String ?? "Unknown Error"
                        print("Phone Number API Error: \(errorMessage)")
                    }
                } catch {
                    print("JSON Parsing Error: \(error)")
                }
            }
        }.resume()
    }

}



struct Screen2View: View {
    @Binding var otp: String
    var phoneNumber: String
    @Binding var authToken: String
    @Binding var isComplete: Bool
    @State private var timer: Timer?
    @State private var countdown = 59
    
    var body: some View {
        VStack {
            Text("Enter The OTP")
                .font(.title)
                .padding()
            
            HStack {
                Text("Enter the OTP sent to")
                    .font(.headline)
                    .foregroundColor(.gray)
                
                Text(phoneNumber)
                    .font(.headline)
            }
            .padding(.vertical)
            
            TextField("OTP", text: $otp)
                .keyboardType(.numberPad)
                .padding()
            
            Button(action: {
                makeOTPAPI()
            }) {
                Text("Continue")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(Color.yellow)
                    .cornerRadius(10)
            }
            .padding()
            
            Text("Resend OTP in \(countdown) seconds")
                .font(.footnote)
                .foregroundColor(.gray)
                .onAppear {
                    startTimer()
                }
        }
        .padding(.vertical, 40)
    }
    
    func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if countdown > 0 {
                countdown -= 1
            } else {
                timer?.invalidate()
            }
        }
    }

    
    func makeOTPAPI() {
        guard let url = URL(string: "https://app.aisle.co/V1/users/verify_otp") else {
            return
        }
        
        let parameters = [
            "number": "+91" + phoneNumber,
            "otp": otp
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted)
        } catch {
            print("JSON Serialization Error: \(error)")
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                do {
                    let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
//                    print("otp jsonResponse :",jsonResponse)
                    if let authToken = jsonResponse?["token"] as? String {
                        // Handle successful response
                        DispatchQueue.main.async {
                            self.authToken = authToken
                            self.isComplete = true
                        }
                    } else {
                        // Handle unsuccessful response
                        print("OTP API Error: \(jsonResponse?["error"] ?? "Unknown Error")")
                    }
                } catch {
                    print("JSON Parsing Error: \(error)")
                }
            }
        }.resume()
    }
}
struct Screen3View: View {
    var authToken: String
    @Binding var isComplete: Bool
    @State private var likesReceivedCount: Int = 0
    @State private var pendingInvitationsCount: Int = 0
    @State private var profiles: [Profile] = []

    var body: some View {
        VStack {
            Text("Screen 3 Content")
                .padding()
            Button("Make API Call") {
                makeNoteApi()
            }
            .padding()

            // Display Likes and Invites information
            Text("Likes Received Count: \(likesReceivedCount)")
            Text("Pending Invitations Count: \(pendingInvitationsCount)")

            // Display the fetched profile data
            List(profiles, id: \.id) { profile in
                HStack {
                    if let url = profile.imageURL, let data = try? Data(contentsOf: url), let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 60, height: 60) // Adjust size as needed
                            .cornerRadius(30)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Name: \(profile.firstName)")
                        Text("Age: \(profile.generalInfo.age)")
                        Text("Location: \(profile.generalInfo.location.full)")
                        // Add more information as needed
                    }
                }
                .padding()
            }

        }
    }

    // Modify the makeNoteApi function
    func makeNoteApi() {
        guard let url = URL(string: "https://app.aisle.co/V1/users/test_profile_list") else {
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(authToken, forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                do {
                    let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                    print("api jsonResponse", jsonResponse)

                    if let likesData = jsonResponse?["likes"] as? [String: Any] {
                        likesReceivedCount = likesData["likes_received_count"] as? Int ?? 0
                    }

                    if let invitesData = jsonResponse?["invites"] as? [String: Any] {
                        pendingInvitationsCount = invitesData["pending_invitations_count"] as? Int ?? 0

                        if let profilesData = invitesData["profiles"] as? [[String: Any]] {
                            profiles = profilesData.map { profileData in
                                return Profile(from: profileData)
                            }
                        }
                    }

                    // Mark the process as complete
                    DispatchQueue.main.async {
                        isComplete = false
                    }
                } catch {
                    print("JSON Parsing Error: \(error)")
                }
            }
        }.resume()
    }



    struct Profile {
        var id: Int
        var firstName: String
        var generalInfo: GeneralInfo
        var imageURL: URL? // Add an image URL property
        
        init(from data: [String: Any]) {
            id = data["id"] as? Int ?? 0
            firstName = data["first_name"] as? String ?? ""
            generalInfo = GeneralInfo(from: data["general_information"] as? [String: Any] ?? [:])
            
            if let imageString = data["profile_image"] as? String, let url = URL(string: imageString) {
                imageURL = url
            }
        }
    }


struct GeneralInfo {
    var age: Int
    var location: Location
    
    init(from data: [String: Any]) {
        age = data["age"] as? Int ?? 0
        location = Location(from: data["location"] as? [String: Any] ?? [:])
    }
}

struct Location {
    var full: String
    
    init(from data: [String: Any]) {
        full = data["full"] as? String ?? ""
    }
}

}



struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
