# Agent

## Agent 整體鏈路

### 什麼是 Agent

「Agent」可以有多種定義。一些人將 Agent 定義為完全自主的系統，能夠在較長時間內獨立運行，使用各種工具完成複雜任務。也有人使用該術語來描述遵循預定義工作流程、具有更高規範性的實作。

**Agent 的組成部分**

![fig1](https://raw.githubusercontent.com/Linshu-Song/SAIL_image_hosting/main/Agentimg/fig1.png)

圖片來源：https://www.bilibili.com/video/BV1uNk1YxEJQ?spm_id_from=333.788.videopod.episodes&vd_source=cdbd526603d180d53ccd6caa6a2ec439&p=8

從工程實作的角度，可以將 Agent 拆分為四個核心模組：**推理、記憶、工具、行動**。

---

### Agent 完整工作流程

我們認為，僅僅是一個簡單的 LLM（Prompt）並不能被稱為 Agent。Agent 系統的基本構建模組，是一個透過檢索、工具與記憶等能力增強的 LLM。現有模型可以主動利用這些能力，生成自己的搜尋查詢、選擇合適的工具，並決定需要保留哪些資訊。

🧩🧩🧩

![fig1](https://raw.githubusercontent.com/Linshu-Song/SAIL_image_hosting/main/Agentimg/fig2.png)

Agent 的重點不在於模型本身，而是在於讓模型真正具備完成任務的能力。

🧩🧩🧩🧩

![fig1](https://raw.githubusercontent.com/Linshu-Song/SAIL_image_hosting/main/Agentimg/fig3.png)

Agent 決策流程圖

圖片來源：https://www.bilibili.com/video/BV1uNk1YxEJQ?spm_id_from=333.788.videopod.episodes&vd_source=cdbd526603d180d53ccd6caa6a2ec439&p=8

**感知：** 需要從外部環境接收輸入，需要知道使用者提出的問題是什麼。有了感知之後，便會將內容交給 LLM。

**規劃：** 透過 LLM 的規劃能力對任務進行拆解，以更有效地解決問題。

關於子任務拆分原則：應盡量保持子任務之間彼此獨立，每個任務對應一個 Tool，這樣有利於工程化，同時每一步都應具有明確的輸出。Agent 的拆分粒度過粗會降低可靠性，過細則會增加推理成本與上下文複雜度，因此在工程實踐中通常希望每個步驟都對應一個明確的目標與可驗證的輸出。

**行動：** 解決目前的子任務並獲得回饋。

**觀察：** 我們無法立即判斷這個回饋是好還是壞，因此需要進行反思。如果結果良好，就繼續規劃下一個任務；如果結果不好，就思考是否需要重新制定下一步的規劃。

---

### LLM 在 Agent 框架中的作用

LLM 在整個框架中更像是負責推理與決策的大腦，但它本身無法直接與外界互動，也不能直接面向使用者。若沒有 Runtime，即使模型知道應該如何做，也沒有執行環境，就像一個人被放置於虛無之中，無法真正完成任何任務。

**LLM 回答的方式：**

從本質上來說，LLM 的回答方式其實只有一種：

> 思考（Reason）  
> 如有需要則呼叫工具（Act）  
> 獲得結果（Observation）  
> 生成最終答案（Final Answer）

差別僅在於：

有些問題不需要存取外部環境，例如：

> Hi, how are you?

LLM 可以直接根據已有知識生成答案；

更多時候，LLM 會發現自己缺乏必要資訊，或需要執行某些操作，因此會要求 Runtime 呼叫對應的 Tool。工具不只是 API，也可能是 MCP、資料庫、RAG 檢索、搜尋引擎、本地程式碼執行器，甚至其他 Agent。

因此，不應簡單地理解為存在「兩種回答方式」，而應理解為：

最終一定是先完成任務，再生成答案。只是有些任務剛好不需要呼叫工具而已。

需要注意的是，大模型本身通常很難主動承認：

```text
這個問題無法解決
我沒有找到答案
我不確定
```

在真正無法解決問題時，如果沒有額外限制，模型往往不會自動停止，而是繼續搜尋、規劃，甚至開始產生幻覺（Hallucination），編造出看似合理但實際上錯誤的答案。因此，在實際工程中，Agent 的循環次數、Tool Call 次數或 Planning 次數，通常都會由 Runtime 人為設定上限。

沒有 Runtime 的 LLM（Prompt）不能被稱為 Agent，真正讓 Agent 具備工程能力的核心在於 Runtime。

---

## Agent Runtime

### Runtime 是什麼

Runtime 本質上是 AI Agent 的執行基礎設施。它負責管理 Agent 的生命週期、狀態、運算資源以及與外部系統的互動，從而確保 Agent 能夠可靠、安全且大規模地運行。它是讓 Agent 能夠執行、處理輸入、完成任務並即時或近即時交付輸出的基礎設施或平台。

> 負責：  
> 維護 State 與 Session；  
> 管理 Memory；  
> 呼叫 Tool；  
> 控制工作流程；  
> 處理權限與例外；  
> 組織 Context；  
> 與外部環境互動。

🧩🧩🧩

![fig1](https://raw.githubusercontent.com/Linshu-Song/SAIL_image_hosting/main/Agentimg/fig4.png)

典型 Runtime

當 LLM 判斷需要使用工具時，它會將 Tool Call 的意圖交給 Runtime，再由 Runtime 透過 MCP Client 呼叫對應的 MCP Server。

但是，這條流程中其實還缺少了一個重要的部分：

> 「我要搜尋圖書館是否有《哈利波特》。」  
> 「這本書在哪裡？」  
> 「這本書」到底指的是哪一本？

**State：** 這裡隱藏了一個稱為 **State** 的概念。State 會記錄使用者是否已登入、個人資訊、是否有借書、是否欠款、身分權限等資訊。每一次都會與 Input 一起傳入 LLM 進行分析，這樣才能知道先前提到的「這本書」究竟是哪一本，進而呼叫正確的 API。

---

### Context

LLM 每一輪並不是只看目前這一句話，而是會同時接收 **System Prompt、工具列表、對話歷史、Session/User State、權限狀態、檢索結果以及目前的使用者輸入**。Runtime 負責將這些資訊組織成可控的執行流程。

Context 表示大模型每次處理任務時所接收到的資訊總和。Context 中包含許多內容，例如對話歷史、使用者問題、目前輸出、工具列表以及 System Prompt 等，可以理解為大模型的暫時性記憶。

主流模型的 **Context Window（上下文視窗）** 表示大模型每次接收任務時所能容納的最大 Token 數量。

而 Context 能夠包含多少資訊、能容納多少 Token，則是由 Context Window 所決定。

🧩🧩🧩

![fig1](https://raw.githubusercontent.com/Linshu-Song/SAIL_image_hosting/main/Agentimg/fig5.png)

請注意，**Context Window 並不等於 Memory。**
**AI Agent 的記憶類型**

記憶 Memory：分為短期記憶以及長期記憶。

**形成記憶：** 大模型在大量包含世界知識的資料集上進行預訓練。在預訓練中，大模型透過調整神經元的權重來學習和理解如何生成人類語言，這可以被視為「記憶」的形成過程。透過使用深度學習和梯度下降等技術，模型不斷提升預測或生成文本的能力，進而形成長期記憶。這些記憶存在於硬體中，不會遺忘。

**短期記憶／工作記憶**

短期記憶（Short-term Memory, STM）是智能體維護目前對話和任務即時上下文的系統，主要包括：

會話緩衝（Context）記憶：保留最近對話歷史的滾動視窗，確保回答與上下文相關；

工作記憶：儲存目前任務的臨時資訊，例如中間結果、變數值等。

短期記憶受限於上下文視窗大小，適用於簡單對話和單一任務場景。

**長期記憶**

長期記憶（Long-term Memory, LTM）是智能體用於跨會話、跨任務長期保存知識的記憶形式。它對應於人類大腦中持久保存的記憶，例如事實知識、過去經歷等。長期記憶的實作通常依賴外部儲存或知識庫，包括但不限於：

- 摘要記憶：將長對話內容提煉為關鍵摘要儲存；
- 列表項結構化知識庫：使用資料庫或知識圖譜儲存結構化資訊；
- 列表項向量化儲存：透過向量資料庫實現基於語義的記憶檢索。

長期記憶使智能體能夠隨著時間累積經驗和知識，特別適用於知識密集型應用和需要長期個人化的場景。

![fig1](https://raw.githubusercontent.com/Linshu-Song/SAIL_image_hosting/main/Agentimg/fig6.png)

---

### 會話語境（Conversation Memory）中的 Session State 和 Memory

目前常用的上下文記憶解決方法：

Session：表示目前的對話線程。它表示使用者與 Agent 系統之間一次正在進行的互動過程。它包含在這次特定互動過程中，使用者訊息以及 Agent 所執行的操作（稱為 Events）的時間順序記錄。一個 Session 也可以保存僅在目前會話期間有效的臨時資料（SessionState）。

State（session.state）：表示目前對話中的資料。它是儲存在某一個特定 Session 內部的資料，用於管理僅與目前活躍會話相關的資訊，例如目前聊天中的購物車內容，或者使用者在本次會話中提到的偏好設定。

Memory：表示一個可能跨越多個歷史 Session，或者包含外部資料來源的資訊儲存系統。它充當一個知識庫，Agent 可以透過搜尋它來回憶資訊，或者獲取目前會話之外的上下文內容。

除了 Chat API 自己管理 memory 之外，也存在另一種基於 Session 的 API 模式。比如 Completion API 不會傳送 context，而是只傳送目前的狀態以及 session id，並在服務端記住 session。Gemini 和 Claude 也都支援這兩種方式。客戶端只需要傳送目前輸入以及 session_id，歷史記錄由服務端維護，開發者無需自己管理 Conversation History。需要注意的是，無論是 Chat API 還是傳統 Completion API，本身都是無狀態的，兩者都可以攜帶歷史資訊，也都可以只傳送目前輸入，區別主要在於輸入格式和上下文管理方式，而不是模型是否具有記憶能力。

本質上，它們都屬於 Conversation Memory 的實作方式，兩者解決的都是短期上下文記憶問題。

Conversational Context: Session, State, and Memory - Agent Development Kit (ADK)

**Summarized memory（摘要記憶）：** 短期記憶能夠保證對話的連續性，但它無法擴展。隨著對話時間延長，盲目地重放每一條資訊會變得既費時費力又不可靠。Summarized 記憶可以解決這個問題。

它捕捉到了：

> 使用者意圖  
> 重要事實  
> 決策與約束

它明確表示不儲存：

> 每一句話  
> 閒聊  
> 冗餘確認

https://medium.com/@sitaramireddy1994/summarized-memory-in-ai-agents-compressing-conversation-without-losing-intent-c0cf7678071c

## **Agent 能力來源（Tool）**

### Tool

工具 Tools：LLM 不具備任何與外部環境互動的能力，沒有環境互動它就無法完成任何事情，而工具是環境的一部分。但是，它可以透過外接 API 的形式獲得模型權重中所缺少的額外資訊。這對於預訓練之後難以修改的模型權重來說非常重要。Tool 的存在與權限由開發者定義，而是否呼叫某個 Tool，則由 LLM 在 Runtime 環境下根據目前任務動態決定。可以透過提示工程激發或引導模型已有的能力，但實際上這些能力是固化的，能力上限仍然由模型權重決定。有些模型天生能力就強，但有些模型即使加入提示詞也不會有很好的結果。

🧩🧩🧩

![fig1](https://raw.githubusercontent.com/Linshu-Song/SAIL_image_hosting/main/Agentimg/fig7.png)

### MCP

即使擁有最前沿的模型，如果無法連接外部世界以獲得必要資料和上下文，效果也會大打折扣。

- 列表項模型上下文協議（MCP）是一個開源協議，它標準化了大語言模型的連接與工作方式。可以理解為一套統一的工具接入標準（例如所有手機都使用 Type-C 接口）。它也是 Runtime 使用的一種工具，與其他工具不同之處在於它是一個打包好的黑盒。MCP 協議可以為 LLM Agent 提供數百種工具來解決現實任務。MCP 伺服器的優勢在於跨應用（不同 Runtime）的高度可複用性。

MCP 的意義在於提供統一的工具接口。不同模型（GPT、Claude、Qwen 等）雖然接口各不相同，但都可以透過統一的 MCP 協議存取工具，這樣切換模型時就不需要重寫底層邏輯。

- 列表項從工程角度看，MCP Server 本質上可以理解為一個 Wrapper，它把真實的 API、資料庫、RAG、搜尋引擎等能力統一封裝成標準接口，供 Runtime 呼叫。

- 列表項不過，MCP 也是一種比較「重」的方案。因為所有能力都需要按照 MCP 規範進行包裝，就像隨身攜帶一個完整工具箱。對於大型系統、複雜 Agent 和多模型場景，這種標準化帶來了巨大的擴展性；但如果只是簡單呼叫一個工具，那麼直接呼叫 API 往往更加輕量，不一定需要引入整個 MCP 體系。

### Tool Calling

- 列表項有的 Tool 都會被打包成一個 MCP Server 接口給 MCP Client。為什麼要先打包成 MCP Server 而不是直接連接呢？為什麼不能直接把 API 接過來呢？這裡是工程學的問題，因為模型會一直變，比如今天使用 GPT，明天換成 Qwen，它們的接口是不一樣的，換了就要重寫。但所有模型都支援 MCP 接口，也許有自己的格式，但都會支援 MCP 接口，這樣換模型就不需要進行修改。

- 列表項 MCP Client 只知道需要這個 Tool，不會知道具體怎麼做，但是會幫忙呼叫 MCP Server。這就是 LangGraph 的用處，不能讓 LLM 做權限控制，因為它會有幻覺。我們可以在呼叫 Tool 之前先插入一個權限驗證，通過之後 Agent Runtime 再呼叫 MCP Client。

- 列表項 MCP Server 可以理解為把外部工具、資料庫、檔案系統、搜尋服務或業務 API 包裝成統一協議的服務端；MCP Client 則在 Agent Runtime 中負責發現工具、讀取工具描述、發起呼叫並接收結果。這樣模型或上層框架變化時，底層工具接入方式不需要全部重寫。

真正的業務邏輯仍然在 MCP Server 背後的 API、資料庫或服務中，Agent Runtime 只透過協議化接口呼叫它們。

### Skill

Skill 只需要在我們需要做某件事時再載入需要的內容，按需求決定做什麼；可是 Tool 需要把所有東西都先載入好。Skill 可以理解為一份壓縮好的說明書，模型也許實際上懂得怎麼做，但對於目前的 Runtime 可能並不符合它的規範，那麼我們就需要到達 Runtime 之後再打開這份說明書，找到對應的說明。在開始之前，不需要把所有需求都背下來。Skill 裡面還包裹了工具和腳本，但這並不是模型本身的工具，而是 Runtime 需要提供給模型的工具。只是如果沒有這份說明書，我們就不知道如何找到或者如何使用這個工具。

## RAG

檢索增強生成（RAG）是指對大語言模型輸出進行優化，使其能夠在生成回應之前引用訓練資料來源之外的權威知識庫。大語言模型（LLM）使用海量資料進行訓練，並利用數十億個參數為回答問題、翻譯語言和完成句子等任務生成原始輸出。在 LLM 本就強大的能力基礎上，RAG 將其擴展為能夠存取特定領域或組織內部知識庫的系統，而這一切都無需重新訓練模型。這是一種經濟高效地改進 LLM 輸出的方法，使其在各種情境下都能保持相關性、準確性和實用性。

### RAG 流程

🧩🧩🧩🧩

![fig1](https://raw.githubusercontent.com/Linshu-Song/SAIL_image_hosting/main/Agentimg/fig8.png)

一個完整的 RAG 鏈路通常包括：文件清洗與切分（chunking）、embedding 建庫、query 改寫或擴展、retrieval 召回、rerank 重排、上下文壓縮、引用來源保留、LLM 生成和答案校驗。

在加入 RAG 之前，LLM 的知識來源只有訓練資料；加入 RAG 之後，系統會先去尋找相關資料，然後把資料交給 LLM。LLM 本身不變，但 prompt 變長了。

### Chunking

把長文件切成小段再存入向量庫。

- 列表項切太小，例如每段 100 tokens，可能會丟失上下文。比如一段只寫「該方法適用於上述情況」，但「上述情況」在上一段，檢索出來後 LLM 也看不懂。
- 列表項切太大，例如每段 2000 tokens，雖然上下文完整，但語義太雜，embedding 會被很多無關資訊稀釋，導致召回不準。

Chunk size 通常並不是固定答案，一般要根據文件類型以及任務進行調整。一般文件大約為 300-800 tokens；程式碼或表格通常需要按照結構切分；注意要保留標題章節以及 metadata。

有時會使用 overlap 來避免答案剛好被切斷，常用 overlap 為 10%-20%。

### Embedding

RAG 中的 Embedding：這通常是一個單獨的模型，可以理解為一個語義索引工具，會把文件轉化為一個向量，然後存進向量資料庫。

> 舉例：比如你有一篇文件：哈利波特是一本魔法小說。

Embedding 模型會把它變成一個向量，然後存進向量資料庫。

當使用者問：哪裡能找到哈利波特？也會被轉成向量。

系統會比較兩個向量是否接近：使用者問題向量 vs 文件片段向量

如果距離很近，說明語義相關，就把這段文件找出來，再交給 LLM 回答。

選擇 embedding 要看語言、領域和評測結果。中文場景可以考慮 bge、m3e、e5、text-embedding 系列。維度高不一定更好，會增加儲存和檢索成本。領域差異大時，可以考慮微調 embedding 或引入混合檢索。

### Retrieval

系統在收到 Query 之後不會先去問 LLM，而是先去相關知識庫中搜尋，並將相關的檢索結果進行上下文增強。

### Reranking

返回的結果會有很多，我們需要的是最好的前幾個。如何保證拿到最相關的內容、如何設計流程、如何讓 LLM 在沒有相關內容時不要亂回答，都是需要考慮的問題。

Retrieval 負責盡量召回相關內容，Rerank 負責從候選結果中挑出最適合放入 context 的片段。兩者目標不同：召回階段寧可多拿一些，重排階段再控制品質和 token 成本。