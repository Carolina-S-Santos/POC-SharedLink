//
//  ViewController.swift
//  poc_sharedlink
//
//  Created by Carolina Silva dos Santos on 11/06/25.
//
import Foundation
import CloudKit
import UIKit

class ViewController: UIViewController {
    
    var groupIDCreated: String?
    
    lazy var permissionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        return label
    }()

    lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        return label
    }()

    lazy var nomeGrupoTextField: UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.borderStyle = .roundedRect
        return textField
    }()

    lazy var groupNameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        return label
    }()

    lazy var usersLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    lazy var createGroupButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Criar Grupo", for: .normal)
        button.addTarget(self, action: #selector(createGroup), for: .touchUpInside)
        return button
    }()

    lazy var shareLinkButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Gerar Link do Grupo", for: .normal)
        button.addTarget(self, action: #selector(handleShareLink), for: .touchUpInside)
        return button
    }()

    
    @objc func createGroup() {
        // 1. Solicite permissão para descobrir o usuário (uma vez por sessão/app)
        requestPermission { [weak self] granted in
            guard granted else {
                print("Permissão negada para descobrir usuário")
                self?.permissionLabel.text = "Permission denied"
                return
            }
            self?.permissionLabel.text = "Permission granted"
            
            // 2. Busque o recordID do usuário logado
            self?.fetchiCloudUserRecordID { meuRecordName, userName, icloudID in
                guard let meuRecordName = meuRecordName, let icloudID = icloudID else {
                    // erro
                    return
                }
                let user = User(name: userName ?? "Desconhecido", icloudRecordID: icloudID)
                
                // (Opcional) Exibe o nome do usuário, se obtido
                if let userName = userName {
                    self?.nameLabel.text = userName
                } else {
                    self?.nameLabel.text = "Unknown"
                }
                
                // 3. Crie o grupo normalmente
                guard let nome = self?.nomeGrupoTextField.text, !nome.isEmpty else {
                    print("Digite um nome para o grupo!")
                    return
                }
                
                let groupRecord = CKRecord(recordType: "Group")
                groupRecord["name"] = nome as CKRecordValue
                groupRecord["users"] = [user.name] as CKRecordValue
                groupRecord["userIDs"] = [meuRecordName] as CKRecordValue
                
                let db = CKContainer.default().publicCloudDatabase
                db.save(groupRecord) { savedRecord, error in
                    if let error = error {
                        print("Erro ao salvar grupo:", error)
                    } else if let savedRecord = savedRecord {
                        let groupId = savedRecord.recordID.recordName
                        // 1. Salve o groupID no seu estado local (variável), e no UserDefaults
                        self?.groupIDCreated = groupId
                        UserDefaults.standard.set(groupId, forKey: "groupID_atual")
                        
                        // 2. Gere o link customizado
                        let customURL = "pocsharedlink://join?groupId=\(groupId)"
                        print("Link customizado:", customURL)
                    }
                }
            }
        }
    }

    
    private func requestPermission(completion: @escaping (Bool) -> Void) {
        CKContainer.default().requestApplicationPermission([.userDiscoverability]) { status, error in
            DispatchQueue.main.async {
                completion(status == .granted)
            }
        }
    }

    // Fetch + Discover, retorna recordName e nome (se houver)
    private func fetchiCloudUserRecordID(completion: @escaping (String?, String?, String?) -> Void) {
        CKContainer.default().fetchUserRecordID { [weak self] recordID, error in
            if let id = recordID {
                self?.discoveriCloudUser(id: id) { name in
                    completion(id.recordName, name, id.recordName)
                }
            } else {
                completion(nil, nil, nil)
            }
        }
    }


    // Descobre o nome do usuário, retorna via closure
    private func discoveriCloudUser(id: CKRecord.ID, completion: @escaping (String?) -> Void) {
        CKContainer.default().discoverUserIdentity(withUserRecordID: id) { identity, error in
            DispatchQueue.main.async {
                if let name = identity?.nameComponents?.givenName {
                    completion(name)
                } else {
                    completion(nil)
                }
            }
        }
    }

    
    @objc func handleShareLink() {
        let groupId = groupIDCreated
            let customURL = "pocsharedlink://join?groupId=\(groupId)"
            
            UIPasteboard.general.string = customURL
            // Feedback para o usuário:
            let alert = UIAlertController(title: "Link copiado!", message: "O link do grupo foi copiado para a área de transferência.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            DispatchQueue.main.async {
                self.present(alert, animated: true)
            }

    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
//
//        let grupo = Group(name: "Nome", startDate: Date(), duration: 12345, prize: "Prêmio")
//        
//        let user1 = User(nickname: "User 1", title: "foda")
//        let user2 = User(nickname: "User 2", title: "brabo")
//        
//        grupo.users = [user1, user2]
//        
//        let task1 = Task(title: "Tarefa 1", description: "Descricao 1", type: .cleaning, level: 2)
//        let task2 = Task(title: "Tarefa 2", description: "Descricao 2", type: .dishes, level: 1)
//        
//        grupo.tasks = [task1, task2]
//        
//        let grupo2 = Group(name: "Nome", startDate: Date(), duration: 12345, prize: "Prêmio")
//        
//        let user3 = User(nickname: "User 3", title: "foda")
//        let user4 = User(nickname: "User 4", title: "brabo")
//        
//        grupo.users = [user3, user4]
//        
//        let task3 = Task(title: "Tarefa 3", description: "Descricao 1", type: .cleaning, level: 2)
//        let task4 = Task(title: "Tarefa 4", description: "Descricao 2", type: .dishes, level: 1)
//        
//        grupo.tasks = [task3, task4]
//        
//        salvarGrupoNoCloudKit(grupo) { result in
//            switch result {
//            case .success(let record):
//                print("Grupo salvo com sucesso! ID: \(record.recordID.recordName)")
//            case .failure(let error):
//                print("Erro ao salvar grupo: \(error.localizedDescription)")
//            }
//        }
//        
//        salvarGrupoNoCloudKit(grupo2) { result in
//            switch result {
//            case .success(let record):
//                print("Grupo salvo com sucesso! ID: \(record.recordID.recordName)")
//            case .failure(let error):
//                print("Erro ao salvar grupo: \(error.localizedDescription)")
//            }
//        }
                
//        let container = CKContainer.default()
//
//        container.fetchUserRecordID { recordID, error in
//            if let error = error {
//                print("❌ Error fetching user record ID: \(error.localizedDescription)")
//                return
//            }
//
//            guard let recordID = recordID else {
//                print("❌ No user record ID returned.")
//                return
//            }
//
//            print("✅ Fetched iCloud user record ID: \(recordID.recordName)")
//
//            // Request permission for discoverability
//            container.requestApplicationPermission([.userDiscoverability]) { status, error in
//                if let error = error {
//                    print("❌ Error requesting permission: \(error.localizedDescription)")
//                    return
//                }
//
//                if status == .granted {
//                    print("✅ Discoverability permission granted.")
//
//                    container.discoverUserIdentity(withUserRecordID: recordID) { identity, error in
//                        if let error = error {
//                            print("❌ Error discovering identity: \(error.localizedDescription)")
//                            return
//                        }
//
//                        if let name = identity?.nameComponents?.givenName {
//                            print("👤 User name: \(name)")
//                        } else {
//                            print("⚠️ Could not retrieve user name.")
//                        }
//                    }
//                } else {
//                    print("⚠️ Discoverability permission not granted.")
//                }
//            }
//        }
        
        if let groupID = UserDefaults.standard.string(forKey: "groupID_atual") {
            groupIDCreated = groupID // deixa o estado sincronizado
            fetchGroupFromCloudKit(groupID) { group in
                if let group = group {
                    self.groupNameLabel.text = group.name
                    self.usersLabel.text = "Usuários: \(group.users.map { $0.name }.joined(separator: ", "))"
                } else {
                    print("Grupo não localizado")
                }
            }
        }


        view.backgroundColor = .systemBackground
    }
    
    func fetchGroupFromCloudKit(_ groupID: String, completion: @escaping (Group?) -> Void) {
        let db = CKContainer.default().publicCloudDatabase
        let recordID = CKRecord.ID(recordName: groupID)
        
        db.fetch(withRecordID: recordID) { record, error in
            if let error = error {
                print("Erro ao buscar grupo:", error)
                completion(nil)
                return
            }
            
            if let groupRecord = record {
                let name = groupRecord["name"] as? String ?? "Sem nome"
                let userNames = groupRecord["users"] as? [String] ?? []
                let userIDs = groupRecord["userIDs"] as? [String] ?? []

                // Crie usuários combinando nome e ID
                var users: [User] = []
                for (i, name) in userNames.enumerated() {
                    let id = i < userIDs.count ? userIDs[i] : nil
                    let user = User(name: name, icloudRecordID: id)
                    users.append(user)
                }
                let group = Group(name: name)
                group.users = users
                completion(group)
            }
        }
    }


//    func salvarGrupoNoCloudKit(_ grupo: Group, completion: @escaping (Result<CKRecord, Error>) -> Void) {
//        let record = CKRecord(recordType: "Group")
//        
//        // Preenchendo os campos do record com os valores do grupo
//        record["id"] = grupo.id.uuidString as CKRecordValue
//        record["name"] = grupo.name as CKRecordValue
//
//        // Para campos de lista (users, tasks), salve os IDs ou nomes como [String]
//        record["users"] = grupo.users.map { $0.id.uuidString } as CKRecordValue
//
//        // Salvar no banco público
//        let publicDatabase = CKContainer.default().publicCloudDatabase
//        publicDatabase.save(record) { savedRecord, error in
//            if let error = error {
//                print("deu erro")
//                completion(.failure(error))
//            } else if let savedRecord = savedRecord {
//                print("salvou")
//                completion(.success(savedRecord))
//            }
//        }
//    }

}

extension ViewController: ViewControllerProtocol {
    func setup() {
        addSubviews()
        setupConstraints()
    }
    
    func addSubviews() {
        view.addSubview(permissionLabel)
        view.addSubview(nameLabel)
        view.addSubview(nomeGrupoTextField)
        view.addSubview(createGroupButton)
        view.addSubview(groupNameLabel)
        view.addSubview(usersLabel)
        view.addSubview(shareLinkButton)
    }
    
    func setupConstraints() {
        NSLayoutConstraint.activate([
            permissionLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            permissionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            permissionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            nameLabel.topAnchor.constraint(equalTo: permissionLabel.bottomAnchor, constant: 12),
            nameLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            nameLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            nomeGrupoTextField.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 24),
            nomeGrupoTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            nomeGrupoTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            nomeGrupoTextField.heightAnchor.constraint(equalToConstant: 44),

            createGroupButton.topAnchor.constraint(equalTo: nomeGrupoTextField.bottomAnchor, constant: 20),
            createGroupButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            groupNameLabel.topAnchor.constraint(equalTo: createGroupButton.bottomAnchor, constant: 30),
            groupNameLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            groupNameLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            usersLabel.topAnchor.constraint(equalTo: groupNameLabel.bottomAnchor, constant: 8),
            usersLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            usersLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            shareLinkButton.topAnchor.constraint(equalTo: usersLabel.bottomAnchor, constant: 28),
            shareLinkButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
            
        ])
    }
}

extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
