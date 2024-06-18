import SwiftUI
import WebKit

// WebView の定義
struct WebView: UIViewRepresentable {
    let url: URL
    let scale: CGFloat

    func makeUIView(context: Context) -> WKWebView {
        WKWebView()
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        var urlString = url.absoluteString
        if urlString.contains("youtube.com") || urlString.contains("youtu.be") {
            if urlString.contains("embed") {
                if urlString.contains("?") {
                    urlString += "&autoplay=0&playsinline=1"
                } else {
                    urlString += "?autoplay=0&playsinline=1"
                }
            } else {
                if urlString.contains("?") {
                    urlString = urlString.replacingOccurrences(of: "watch?v=", with: "embed/")
                    urlString += "&autoplay=0&playsinline=1"
                } else {
                    urlString = urlString.replacingOccurrences(of: "watch?v=", with: "embed/")
                    urlString += "?autoplay=0&playsinline=1"
                }
            }
        }
        
        if let newURL = URL(string: urlString) {
            let request = URLRequest(url: newURL)
            uiView.load(request)
            uiView.scrollView.maximumZoomScale = scale
            uiView.scrollView.minimumZoomScale = scale
            uiView.scrollView.zoomScale = scale
        }
    }
}

struct ContentView: View {
    // PhotoData 構造体の定義
    struct PhotoData: Identifiable {
        var id = UUID()
        var imageName: String
        var artist: String
    }
    
    // 曲データ構造体の定義
    struct SongData: Identifiable {
        var id = UUID()
        var title: String
        var url: String
    }
    
    // データの定義
    @State private var photoArray = [
        PhotoData(imageName: "aespa_img", artist: "aespa"),
        PhotoData(imageName: "bigbang_img", artist: "BIGBANG"),
        PhotoData(imageName: "itzy_img", artist: "ITZY"),
        PhotoData(imageName: "ive_img", artist: "IVE"),
        PhotoData(imageName: "stray_kids_img", artist: "Stray_Kids"),
    ].sorted { $0.artist.lowercased() < $1.artist.lowercased() }
    
    // アーティストごとの曲データを格納する辞書
    @State private var artistSongs: [String: [SongData]] = [:]
    
    // CSVファイルを読み込んでアーティストごとの曲データをセットアップする関数
    private func setupSongs() {
        guard let path = Bundle.main.path(forResource: "songs", ofType: "csv") else {
            print("CSV file not found")
            return
        }
        
        do {
            let content = try String(contentsOfFile: path)
            let lines = content.split(separator: "\n")
            
            for line in lines.dropFirst() { // ヘッダー行をスキップ
                let columns = line.split(separator: ",").map { String($0) }
                if columns.count == 3 {
                    let artist = columns[0]
                    let song = columns[1]
                    let url = columns[2]
                    
                    if !artist.isEmpty && !song.isEmpty && !url.isEmpty {
                        let newSong = SongData(title: song, url: url)
                        if artistSongs[artist] == nil {
                            artistSongs[artist] = [newSong]
                        } else {
                            artistSongs[artist]?.append(newSong)
                        }
                    }
                }
            }
            
            // 各アーティストの曲リストをソート
            for artist in artistSongs.keys {
                artistSongs[artist]?.sort { $0.title.lowercased() < $1.title.lowercased() }
            }
        } catch {
            print("Error reading CSV file: \(error)")
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景
                LinearGradient(gradient: Gradient(colors: [Color(red: 28/255, green: 25/255, blue: 45/255), Color(red: 45/255, green: 42/255, blue: 72/255)]), startPoint: .top, endPoint: .bottom)
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    // ヘッダー
                    Rectangle()
                        .foregroundColor(.blue)
                        .frame(height: 100)
                        .overlay(
                            VStack {
                                Text("WEB BookMark")
                                    .font(.title)
                                    .foregroundColor(.white)
                                Text("Welcome to the Web BookMark App!")
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                            }
                        )
                    
                    Spacer()
                    
                    // アーティストごとの曲データ表示
                    ScrollView {
                        VStack(spacing: 20) {
                            ForEach(photoArray.indices, id: \.self) { index in
                                VStack {
                                    NavigationLink(destination: ArtistDetailView(songs: artistSongs[photoArray[index].artist] ?? [], artist: photoArray[index].artist)) {
                                        Image(photoArray[index].imageName)
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 150, height: 150)
                                            .clipShape(Circle())
                                            .shadow(radius: 10)
                                    }
                                    
                                    Text(photoArray[index].artist)
                                        .font(.title)
                                        .fontWeight(.bold)
                                        .frame(maxWidth: .infinity)
                                        .multilineTextAlignment(.center)
                                        .foregroundColor(.white) // 文字色を白に設定
                                }
                                .padding()
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .onAppear {
                if artistSongs.isEmpty {
                    setupSongs()
                }
            }
            .navigationTitle("Artists")
        }
    }
}

struct ArtistDetailView: View {
    var songs: [ContentView.SongData]
    var artist: String
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ForEach(songs) { song in
                    NavigationLink(destination:
                        VStack {
                            WebView(url: URL(string: song.url)!, scale: 0.5) // スケールを設定
                                .frame(height: 300) // WebView の高さを設定
                                .background(
                                    LinearGradient(gradient: Gradient(colors: [Color(red: 28/255, green: 25/255, blue: 45/255), Color(red: 45/255, green: 42/255, blue: 72/255)]), startPoint: .top, endPoint: .bottom) // グラデーションを設定
                                )
                                .edgesIgnoringSafeArea(.all) // 画面全体に拡張
                        }
                    ) {
                        HStack {
                            Text(song.title)
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.white) // 文字色を白に設定
                                .padding()
                            
                            Spacer()
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.blue, lineWidth: 2)
                        )
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
        .background(LinearGradient(gradient: Gradient(colors: [Color(red: 28/255, green: 25/255, blue: 45/255), Color(red: 45/255, green: 42/255, blue: 72/255)]), startPoint: .top, endPoint: .bottom)) // スクロールバーの背景色
        .navigationBarTitle("\(artist)", displayMode: .inline)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
