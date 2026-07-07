# Agent

## Agent Overview

### What is an Agent

The term "Agent" can have multiple definitions. Some people define an Agent as a fully autonomous system capable of operating independently for extended periods of time, using various tools to accomplish complex tasks. Others use the term to describe a more structured implementation that follows predefined workflows.

**Components of an Agent**

![fig1](https://raw.githubusercontent.com/Linshu-Song/SAIL_image_hosting/main/Agentimg/fig1.png)

Image source: https://www.bilibili.com/video/BV1uNk1YxEJQ?spm_id_from=333.788.videopod.episodes&vd_source=cdbd526603d180d53ccd6caa6a2ec439&p=8

From an engineering perspective, an Agent can be decomposed into four core modules: **Reasoning, Memory, Tools, and Actions**.

---

### Complete Agent Workflow

We believe that a standalone LLM (Prompt) should not be considered an Agent. The fundamental building block of an Agent system is an LLM enhanced with capabilities such as retrieval, tools, and memory. Modern models are able to actively utilize these capabilities by generating their own search queries, selecting appropriate tools, and deciding what information should be retained.

🧩🧩🧩

![fig1](https://raw.githubusercontent.com/Linshu-Song/SAIL_image_hosting/main/Agentimg/fig2.png)

The key focus of an Agent is not the model itself, but enabling the model to truly accomplish tasks.

🧩🧩🧩🧩

![fig1](https://raw.githubusercontent.com/Linshu-Song/SAIL_image_hosting/main/Agentimg/fig3.png)

Agent Decision Workflow

Image source: https://www.bilibili.com/video/BV1uNk1YxEJQ?spm_id_from=333.788.videopod.episodes&vd_source=cdbd526603d180d53ccd6caa6a2ec439&p=8

**Perception:** The Agent first receives input from the external environment. It needs to understand what the user is asking before passing the information to the LLM.

**Planning:** The LLM decomposes the task into smaller subtasks to solve the problem more effectively.

Regarding task decomposition, subtasks should be as independent as possible. Ideally, each subtask corresponds to a single Tool, making the system easier to engineer and ensuring that every step has a clear output. If the decomposition is too coarse, reliability decreases; if it is too fine-grained, reasoning cost and context complexity increase. Therefore, in practical engineering, each step is expected to have a clear objective and a verifiable output.

**Action:** Execute the current subtask and obtain feedback.

**Observation:** The Agent evaluates whether the feedback is satisfactory. If the result is good, it proceeds to plan the next task. Otherwise, it reflects on whether the planning strategy should be revised.

---

### The Role of LLMs in the Agent Framework

Within the entire framework, the LLM acts as the brain responsible for reasoning and decision-making. However, it cannot directly interact with the external world or communicate with users on its own. Without a Runtime, even if the model knows what should be done, it has no execution environment—just like a person placed in a void, unable to accomplish any real task.

**How an LLM Responds**

Fundamentally, an LLM has only one response mechanism:

> Reason  
> Act (call tools if necessary)  
> Observation  
> Final Answer

The only difference is:

Some questions do not require access to the external environment. For example:

> Hi, how are you?

In such cases, the LLM can generate an answer directly from its existing knowledge.

More often, however, the LLM realizes that it lacks the necessary information or needs to perform certain operations, and therefore requests the Runtime to invoke the appropriate Tool. A Tool is not limited to APIs—it may also include MCP, databases, RAG retrieval systems, search engines, local code executors, or even other Agents.

Therefore, it is not accurate to think that there are "two different response modes." Instead, the correct understanding is:

The Agent always completes the required task first and then generates the final answer. The only difference is that some tasks simply do not require tool invocation.

It is also worth noting that LLMs generally struggle to explicitly admit:

```text
This problem cannot be solved.
I could not find the answer.
I am not sure.
```

When a problem truly cannot be solved, unless additional constraints are imposed, the model usually does not stop automatically. Instead, it continues searching, planning, or even starts producing hallucinations, generating answers that appear reasonable but are actually incorrect.

Therefore, in practical engineering, the maximum number of Agent iterations, Tool Calls, or Planning steps is typically limited by the Runtime.

An LLM (Prompt) without a Runtime should not be considered an Agent. The Runtime is the core component that enables an Agent to function as an engineering system.

---

## Agent Runtime

### What is Runtime

A Runtime is essentially the execution infrastructure of an AI Agent. It manages the Agent's lifecycle, state, computational resources, and interactions with external systems, ensuring that the Agent can operate reliably, securely, and at scale. It serves as the infrastructure or platform that enables an Agent to execute tasks, process inputs, and deliver outputs in real time or near real time.

> Responsible for:
>
> Maintaining State and Session;  
> Managing Memory;  
> Invoking Tools;  
> Controlling workflows;  
> Handling permissions and exceptions;  
> Organizing Context;  
> Interacting with the external environment.

🧩🧩🧩

![fig1](https://raw.githubusercontent.com/Linshu-Song/SAIL_image_hosting/main/Agentimg/fig4.png)

Typical Runtime

When the LLM determines that a tool is required, it passes the Tool Call request to the Runtime, which then invokes the corresponding MCP Server through the MCP Client.

However, there is one missing piece in this workflow:

> "I want to search whether the library has Harry Potter."  
> "Where can I find this book?"  
> Which book does "this book" actually refer to?

**State:** There is a hidden component called **State**. The State records whether the user is logged in, personal information, borrowed books, outstanding fines, identity, access permissions, and so on. This information is passed into the LLM together with the user's input every time, allowing the model to understand what "this book" refers to and invoke the correct API accordingly.
### Context

In each interaction, an LLM does not only process the current user input. Instead, it simultaneously receives the system prompt, tool list, conversation history, session/user state, permission status, retrieved information, and the current user query. The Runtime is responsible for organizing all of this information into a controllable execution workflow.

Context refers to the complete set of information received by the LLM each time it processes a task. It includes conversation history, user queries, current outputs, tool lists, system prompts, and more. It can be understood as the temporary working memory of the LLM.

The size of the **context window** in mainstream models represents the maximum number of tokens that the model can process in a single request.

The amount of information that Context can contain is determined by the context window, which specifies the maximum number of tokens that can be accommodated.

🧩🧩🧩

![fig1](https://raw.githubusercontent.com/Linshu-Song/SAIL_image_hosting/main/Agentimg/fig5.png)

Note that the **Context Window is not equivalent to Memory**.

---

**Types of Memory in AI Agents**

**Memory:** Memory can be divided into short-term memory and long-term memory.

**Memory Formation:** Large language models are pre-trained on massive datasets containing world knowledge. During pre-training, the model learns to understand and generate human language by adjusting the weights of its neural network. This process is regarded as the formation of "memory." Through deep learning techniques such as gradient descent, the model continuously improves its ability to predict and generate text, thereby forming long-term memory. This memory is stored in the model weights and does not fade over time.

**Short-term Memory / Working Memory**

Short-term Memory (STM) is the mechanism that maintains the immediate context of the current conversation and task. It mainly includes:

- **Conversation Buffer (Context) Memory:** Maintains a rolling window of recent conversation history to ensure contextual consistency in responses.
- **Working Memory:** Stores temporary information required for the current task, such as intermediate results and variable values.

Short-term memory is limited by the size of the context window and is suitable for simple conversations and single-task scenarios.

**Long-term Memory**

Long-term Memory (LTM) is the form of memory that enables an Agent to preserve knowledge across sessions and tasks. It corresponds to persistent memories in the human brain, such as factual knowledge and past experiences. Long-term memory is typically implemented through external storage or knowledge bases, including but not limited to:

- **Summarized Memory:** Stores key summaries extracted from long conversations.
- **Structured Knowledge Base:** Uses databases or knowledge graphs to store structured information.
- **Vectorized Knowledge Storage:** Uses vector databases to enable semantic memory retrieval.

Long-term memory allows an Agent to accumulate knowledge and experience over time. It is particularly suitable for knowledge-intensive applications and scenarios requiring long-term personalization.

![fig1](https://raw.githubusercontent.com/Linshu-Song/SAIL_image_hosting/main/Agentimg/fig6.png)

---

### Session, State, and Memory in Conversation Memory

Common approaches for maintaining conversational context include:

**Session:** Represents the current conversation thread. It refers to an ongoing interaction between a user and an Agent system. A Session contains the chronological record of user messages and the actions (referred to as Events) performed by the Agent during that interaction. A Session can also store temporary data (SessionState) that is only valid during the current conversation.

**State (session.state):** Represents data associated with the current conversation. It is data stored within a specific Session and is used to manage information relevant only to the active conversation, such as the shopping cart in the current chat or user preferences mentioned during this session.

**Memory:** Represents a storage system that may span multiple historical Sessions or include external data sources. It functions as a knowledge base that the Agent can search to recall information or obtain context beyond the current conversation.

Besides the Chat API approach, where memory is managed by the client, there is also a Session-based API approach. For example, the Completion API does not send the conversation context. Instead, it only sends the current state together with the session ID, while the server maintains the session history. Both Gemini and Claude support these two approaches. The client only needs to send the current input and the session ID, while the conversation history is maintained by the server, eliminating the need for developers to manage the conversation history themselves. It should be noted that both the Chat API and the traditional Completion API are fundamentally stateless. Both can include historical information or send only the current input. The primary difference lies in the input format and context management strategy rather than whether the model itself possesses memory.

Essentially, both approaches are implementations of Conversation Memory, and both are designed to solve the problem of short-term conversational context.

Conversational Context: Session, State, and Memory - Agent Development Kit (ADK)

**Summarized Memory:** Short-term memory ensures conversational continuity, but it does not scale well. As conversations become longer, replaying every message becomes inefficient and unreliable. Summarized memory addresses this issue.

It captures:

> User intent  
> Important facts  
> Decisions and constraints

It explicitly does **not** store:

> Every individual sentence  
> Casual conversations  
> Redundant confirmations

https://medium.com/@sitaramireddy1994/summarized-memory-in-ai-agents-compressing-conversation-without-losing-intent-c0cf7678071c

---

## **Sources of Agent Capabilities (Tools)**

### Tool

**Tools:** LLMs themselves do not possess the ability to interact with the external environment. Without interaction with the environment, they cannot accomplish any real tasks. Tools are part of that environment. Through external APIs, they enable the model to obtain additional information that is not contained in its pre-trained weights. This is particularly important because model weights are difficult to modify after pre-training. The availability and permissions of Tools are defined by developers, while whether a particular Tool should be invoked is dynamically decided by the LLM within the Runtime based on the current task. Prompt engineering can encourage or guide the model to utilize its existing capabilities, but these capabilities are fundamentally fixed—the upper limit is still determined by the model's weights. Some models naturally possess stronger capabilities, whereas others may not perform well even with carefully designed prompts.

🧩🧩🧩

![fig1](https://raw.githubusercontent.com/Linshu-Song/SAIL_image_hosting/main/Agentimg/fig7.png)

### MCP

Even with the most advanced models, performance is significantly limited if they cannot connect to the external world to obtain the necessary data and context.

- **Model Context Protocol (MCP):** This is an open protocol that standardizes how large language models connect to and interact with external systems. It can be understood as a unified standard for tool integration (similar to all smartphones using a USB Type-C interface). MCP is also a Runtime tool, but unlike ordinary tools, it is packaged as a black-box interface. The MCP protocol provides LLM Agents with hundreds of tools for solving real-world tasks. The major advantage of MCP Servers lies in their high degree of reusability across different applications and Runtime environments.

The significance of MCP is that it provides a unified interface for tools. Although different models (such as GPT, Claude, and Qwen) have different APIs, they can all access tools through the same MCP protocol, eliminating the need to rewrite the underlying integration logic when switching models.

- From an engineering perspective, an MCP Server can essentially be regarded as a **Wrapper**, encapsulating real APIs, databases, RAG systems, search engines, and other services into a standardized interface for the Runtime to invoke.

- However, MCP is also considered a relatively "heavyweight" solution. Since all capabilities must be packaged according to the MCP specification, it is similar to carrying an entire toolbox. For large-scale systems, complex Agents, and multi-model environments, this standardization provides excellent extensibility. However, when only a single tool needs to be invoked, directly calling the API is often lighter and does not necessarily require introducing the complete MCP ecosystem.

### Tool Calling

- Every Tool can be packaged as an MCP Server and accessed through an MCP Client. Why package it as an MCP Server instead of directly connecting to the API? The reason lies in software engineering. Models are constantly changing—for example, using GPT today and Qwen tomorrow. Their native APIs differ, meaning the integration would need to be rewritten. However, all models support the MCP protocol. Although each model may have its own format, they all support MCP, allowing model replacement without modifying the underlying tool integration.

- The MCP Client only knows that a particular Tool is required; it does not know how the Tool works internally. Its responsibility is to invoke the MCP Server. This is where LangGraph becomes useful. Permission control should not be handled by the LLM itself because hallucinations may occur. Instead, a permission verification step can be inserted before the Tool Call. Once the verification succeeds, the Agent Runtime proceeds to invoke the MCP Client.

- An MCP Server can be understood as a server that wraps external tools, databases, file systems, search services, or business APIs into a unified protocol. The MCP Client, running inside the Agent Runtime, is responsible for discovering available tools, reading tool descriptions, initiating requests, and receiving results. In this way, changes to the model or upper-layer framework do not require rewriting the underlying tool integration.

The actual business logic still resides in the APIs, databases, or services behind the MCP Server. The Agent Runtime interacts with them only through the standardized protocol interface.

### Skill

A Skill only needs to determine what should be loaded when a particular task needs to be performed. It loads resources on demand, whereas a Tool requires everything to be loaded in advance. A Skill can be understood as a compressed instruction manual. The model may already know how to perform a task, but the implementation may not conform to the conventions of the current Runtime. Therefore, once the Runtime is reached, the instruction manual is opened to locate the appropriate instructions. There is no need to memorize every requirement beforehand. A Skill also encapsulates tools and scripts, but these are not the model's own tools—they are tools provided by the Runtime. Without the instruction manual, however, the model would not know how to locate or use those tools.

---

## RAG

Retrieval-Augmented Generation (RAG) is a technique that enhances the outputs of large language models by allowing them to reference authoritative knowledge sources beyond their original training data before generating responses. Large Language Models (LLMs) are trained on massive datasets using billions of parameters to generate outputs for tasks such as question answering, translation, and text completion. Building upon these powerful capabilities, RAG extends LLMs by enabling access to domain-specific or organization-specific knowledge bases without requiring model retraining. It is a cost-effective way to improve the relevance, accuracy, and usefulness of LLM outputs across a wide range of scenarios.

### RAG Workflow

🧩🧩🧩🧩

![fig1](https://raw.githubusercontent.com/Linshu-Song/SAIL_image_hosting/main/Agentimg/fig8.png)

A complete RAG pipeline typically consists of: document cleaning and chunking, embedding generation and vector indexing, query rewriting or expansion, retrieval, reranking, context compression, source citation preservation, LLM generation, and answer verification.

Before introducing RAG, the LLM's knowledge comes solely from its training data. After introducing RAG, the system first retrieves relevant information from external knowledge sources and then provides that information to the LLM. The LLM itself remains unchanged, but the prompt becomes longer because it now includes the retrieved context.

### Chunking

Chunking refers to splitting long documents into smaller segments before storing them in a vector database.

- If the chunks are too small (for example, 100 tokens each), contextual information may be lost. For instance, one chunk may only state "This method is applicable to the above scenario," while the "above scenario" appears in the previous chunk. Even if this chunk is retrieved, the LLM cannot understand its meaning.

- If the chunks are too large (for example, 2,000 tokens each), although the context remains complete, the semantic information becomes too broad. The embedding is diluted by unrelated information, resulting in poor retrieval accuracy.

The optimal chunk size is not fixed. It should be determined according to the document type and the target task. General documents typically use chunk sizes of approximately 300–800 tokens, while code or tables are often split according to their structure. Titles, section information, and metadata should also be preserved.

Overlap is sometimes introduced to prevent answers from being split across chunk boundaries. A common overlap ratio is 10%–20%.

### Embedding

Embedding in RAG is typically performed by a separate model. It can be regarded as a semantic indexing tool that converts documents into vectors and stores them in a vector database.

> Example: Suppose you have a document:
> "Harry Potter is a fantasy novel."

The embedding model converts it into a vector and stores it in the vector database.

When a user asks:

> "Where can I find Harry Potter?"

the query is also converted into a vector.

The system then compares the similarity between the two vectors:

> User query vector vs. document chunk vector

If the vectors are sufficiently close, it indicates semantic relevance. The corresponding document is then retrieved and passed to the LLM for answer generation.

The choice of an embedding model depends on the language, application domain, and benchmark performance. For Chinese applications, models such as **bge**, **m3e**, **e5**, and the **text-embedding** series are common choices. Higher embedding dimensions do not necessarily lead to better performance—they also increase storage and retrieval costs. When there is a significant domain gap, fine-tuning the embedding model or adopting hybrid retrieval can be considered.

### Retrieval

After receiving a query, the system does not immediately send it to the LLM. Instead, it first searches the relevant knowledge base and retrieves related information to augment the context.

### Reranking

Retrieval usually returns many candidate results, but only the best few should be selected. The key challenge is how to ensure that the most relevant results are chosen, and how to prevent the LLM from fabricating answers when the required information does not exist.

Retrieval is responsible for recalling as many relevant candidates as possible, whereas Reranking is responsible for selecting the most appropriate passages to place into the context. Their objectives are different: the retrieval stage prioritizes high recall, while the reranking stage focuses on quality and token efficiency.