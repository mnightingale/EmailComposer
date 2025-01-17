//
//  EmailComposerView.swift
//  
//  Created by Gabriel Theodoropoulos.
//  https://serialcoder.dev
//
//  Licensed under the MIT license.
//

import SwiftUI
import MessageUI

/// A UIViewControllerRepresentable type that brings the
/// MFMailComposeViewController from UIKit to SwiftUI.
struct EmailComposerView: UIViewControllerRepresentable {
    @Environment(\.presentationMode) private var presentationMode
    let emailData: EmailData
    var result: (Result<EmailComposerResult, Error>) -> Void
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let emailComposer = MFMailComposeViewController()
        emailComposer.mailComposeDelegate = context.coordinator
        emailComposer.setSubject(emailData.subject)
        emailComposer.setToRecipients(emailData.recipients)
        emailComposer.setMessageBody(emailData.body, isHTML: emailData.isBodyHTML)
        if emailData.attachments.count > 0 {
            for attachment in emailData.attachments {
                emailComposer.addAttachmentData(attachment.data, mimeType: attachment.mimeType, fileName: attachment.fileName)
            }
        }
        
        return emailComposer
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) { }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
        
    /// Determine if the device can send emails or not.
    /// - Returns: true if the device can send emails, false otherwise.
    public static func canSendEmail() -> Bool {
        MFMailComposeViewController.canSendMail()
    }
    
    ///  Create a URL that will open the devices mail application
    /// - Returns: a URL if the device can open it, nil otherwise
    public static func createEmailUrl(emailData: EmailData) -> URL? {
        let subjectEncoded = emailData.subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        let bodyEncoded = emailData.body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        let to = emailData.recipients?.joined(separator: ",") ?? ""
        
        let gmailUrl = URL(string: "googlegmail://co?to=\(to)&subject=\(subjectEncoded)&body=\(bodyEncoded)")
        let outlookUrl = URL(string: "ms-outlook://compose?to=\(to)&subject=\(subjectEncoded)")
        let yahooMail = URL(string: "ymail://mail/compose?to=\(to)&subject=\(subjectEncoded)&body=\(bodyEncoded)")
        let sparkUrl = URL(string: "readdle-spark://compose?recipient=\(to)&subject=\(subjectEncoded)&body=\(bodyEncoded)")
        let defaultUrl = URL(string: "mailto:\(to)?subject=\(subjectEncoded)&body=\(bodyEncoded)")
        
        if let gmailUrl = gmailUrl, UIApplication.shared.canOpenURL(gmailUrl) {
            return gmailUrl
        } else if let outlookUrl = outlookUrl, UIApplication.shared.canOpenURL(outlookUrl) {
            return outlookUrl
        } else if let yahooMail = yahooMail, UIApplication.shared.canOpenURL(yahooMail) {
            return yahooMail
        } else if let sparkUrl = sparkUrl, UIApplication.shared.canOpenURL(sparkUrl) {
            return sparkUrl
        }
        
        return defaultUrl
    }
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        var parent: EmailComposerView
        
        init(_ parent: EmailComposerView) {
            self.parent = parent
        }
        
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            
            if let error = error {
                parent.result(.failure(error))
                return
            }
            
            parent.result(.success((.init(rawValue: result.rawValue)!)))
            
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
