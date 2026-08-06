# Agent

## Overall Agent Pipeline

### What is an Agent

The term "Agent" can have multiple definitions. Some people define an
Agent as a fully autonomous system that can operate independently for an
extended period and use various tools to complete complex tasks. Others
use the term to describe more structured implementations that follow
predefined workflows.

**Components of an Agent**

Agent is a software system that can perceive the environment, perform
reasoning and decision-making, call tools, and continuously complete
tasks based on feedback. LLMs are usually the reasoning core of an
Agent, but an Agent is not equivalent to an LLM.

From an engineering perspective, an Agent system can be divided into
four core modules:

-   Reasoning
-   Memory
-   Tools
-   Actions

## Agent Workflow

A simple LLM with only prompts should not be considered an Agent. The
basic building block of an Agent system is an LLM enhanced with
retrieval, tools, memory, and other capabilities.

The focus of an Agent is not only the model itself, but enabling the
model to truly complete tasks.

### Agent Decision Process

**Perception:**

The Agent receives input from the external environment and understands
the user's request before passing the information to the LLM.

**Planning:**

The LLM uses planning ability to decompose complex tasks into smaller
steps.

The principle of task decomposition is that subtasks should be as
independent as possible. Each task should correspond to a clear Tool and
produce an explicit output. If the decomposition granularity is too
coarse, reliability decreases; if it is too fine, reasoning cost and
context complexity increase.

**Action:**

The Agent executes the current subtask and obtains feedback.

**Observation:**

The Agent evaluates whether the feedback is useful. If successful, it
continues planning the next step. Otherwise, it reconsideres whether the
current plan should be revised.

## Role of LLM in Agent Framework

The LLM acts as the reasoning and decision-making brain of the Agent.
However, it cannot directly interact with the external world. Without
Runtime, even if the model knows what should be done, it lacks the
execution environment required to complete the task.

In an Agent framework, a common execution pattern is the ReAct
(Reasoning-Acting) loop:

> Reason\
> Act (call tools when necessary)\
> Observation\
> Final Answer

The difference is that some tasks do not require external interaction.
For example:

> Hi, how are you?

The LLM can directly answer based on existing knowledge.

In more complex scenarios, the LLM may determine that additional
information or external operations are required and request Runtime to
call corresponding Tools.

## Agent Runtime

Runtime is the execution infrastructure of an AI Agent. It manages the
Agent lifecycle, state, computing resources, and interactions with
external systems.

Runtime is responsible for:

-   Maintaining State and Session
-   Managing Memory
-   Calling Tools
-   Controlling workflows
-   Handling permissions and exceptions
-   Deciding which information enters Context
-   Interacting with external environments

When the LLM decides that a Tool is required, it sends the Tool Call
intention to Runtime. Runtime then executes the call through the
corresponding Tool interface.

## State, Context and Memory

State stores information that must be maintained during Agent execution,
including user authentication status, permissions, conversation history,
task progress, previous tool calls, tool outputs, and business data.

Runtime does not understand the meaning of information by itself. It
organizes State according to predefined rules or workflows, while the
LLM interprets the information and decides the next action.

Context represents all information received by the model during one
inference process, including:

-   System prompt
-   Tool descriptions
-   Conversation history
-   User input
-   Retrieved information
-   State information

Context is temporary input for the current reasoning process, while
Memory is a mechanism for storing information over a longer period.

Context window represents the maximum number of tokens that a model can
process in one interaction. Context window is not the same as Memory.

## Memory Types

Agent Memory can be divided into short-term memory and long-term memory.

### Short-term Memory

Short-term Memory maintains information required for the current
conversation and task.

It includes:

-   Conversation history
-   Working memory
-   Intermediate results and variables

### Long-term Memory

Long-term Memory stores information across sessions and tasks.

Common implementations include:

-   Summary memory
-   Structured knowledge storage using databases or knowledge graphs
-   Vector-based semantic memory retrieval

## Tools

LLMs cannot directly interact with external environments. Tools provide
interfaces that allow Agents to access external systems and obtain
information beyond model parameters.

The existence and permissions of Tools are defined by developers.
Whether to call a Tool is decided dynamically by the LLM within the
Runtime environment.

Tools define the capability boundary of an Agent. The LLM cannot create
new Tools or automatically discover external capabilities. Only Tools
registered by developers can be used by the Agent.

## MCP

The Model Context Protocol (MCP) is an open protocol that standardizes
the connection between Agent applications and external tools or data
sources.

MCP can be understood as a universal tool connection standard, similar
to the Type-C interface.

The LLM decides whether a Tool should be called based on task
requirements and tool descriptions. Runtime executes the Tool call,
while MCP defines the communication protocol between Runtime and
external Tools.

MCP enables different Agent Runtimes to reuse the same Tool
implementations through MCP Client and MCP Server.

Example:

Claude Desktop → MCP Client → MCP Server

LangGraph → MCP Client → MCP Server

Both Runtime systems can access the same Tools.

MCP mainly solves Tool standardization and reuse problems rather than
directly solving model migration problems.

## Tool Calling

Tools do not necessarily need to be converted into MCP Servers.
Traditional Agents can directly bind Tools, while MCP provides a
standardized method for exposing Tools.

Direct Tool binding is simple and suitable for individual projects.

MCP is useful when multiple Agent applications need to share the same
capabilities, because one Tool implementation can be developed once and
reused across different Runtimes.

MCP Client is responsible for connecting to Servers, obtaining Tool
descriptions, initiating calls, and returning results to Runtime.

MCP Server wraps external capabilities such as APIs, databases, file
systems, search services, or business services into standardized
interfaces.

## Skill

Skill belongs to the Agent capability layer. It describes how an Agent
should complete a certain type of task, including workflows, recommended
Tools, and constraints.

Skill is not a Tool. Instead, it is an instruction manual that provides
task-specific knowledge and procedures.

A Skill usually contains:

-   Task objectives and applicable scenarios
-   Recommended workflow
-   Best practices and constraints
-   Required Tools or scripts

Skill does not execute tasks. Actual execution is performed by Runtime
through Tools.

## RAG

Retrieval-Augmented Generation (RAG) improves LLM responses by providing
external knowledge sources during generation without retraining the
model.

A typical RAG pipeline includes:

-   Document cleaning and chunking
-   Embedding generation
-   Query processing
-   Retrieval
-   Reranking
-   Context construction
-   LLM generation

Before RAG, the LLM mainly relies on training data. After adding RAG,
relevant documents are retrieved and provided as additional context
during inference.

### Chunking

Documents are divided into smaller segments before being stored in a
vector database.

Chunk size should be adjusted according to document type and task
requirements.

### Embedding

Embedding models convert documents and queries into vectors. The system
compares vector similarity between user queries and document fragments
to retrieve relevant information.

### Retrieval and Reranking

Retrieval aims to recall potentially relevant information.

Reranking selects the most useful candidates to place into the model
context while controlling quality and token cost.
