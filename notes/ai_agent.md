# AI Agent：从智能机器人到基于LLM Agent

## 什么是AI Agent

AI Agent是能够和环境进行交互、收集信息，并利用这些信息进行决策并采取行动以实现特定目标的智能系统。

### 类型

![Agent Types](./assets/ai_agent/agent_types.png)
- 简单反应agent：对输入做响应
- 基于模式的agent：具备一定的记忆能力，可以根据状态来调整相应
- 目标型agent：具备规划能力
- 基于效用的agent：可以评估不同的方案，给出最优解
- 学习型agent：具体学习和提高能力

### AI Agent的历史

Agent的发展主要可以分为三个阶段：早期智能机器人 》 智能问答机器人 》 基于LLM的AI Agent

### 阶段一：早期智能机器人，基于规则和专家系统，功能相对简单。比如：
- **ELIZA（1966）**：早期的自然语言对话程序，模拟心理咨询师，通过简单的规则进行对话。
- **Expert Systems（如DENDRAL, MYCIN）**：基于规则的专家系统，应用于化学分析和医学诊断等领域。
这些早期机器人主要依赖于人工编写的规则和知识库，智能水平有限，为后续AI Agent的发展奠定了基础。
![基于规则和专家系统智能机器人](./assets/ai_agent/rule_based_expert_system.jpg)

### 阶段二：基于机器学习和大数据的智能问答与助手系统，代表性产品包括：
- **Siri（2011）、小艺、小度、小爱同学、天猫精灵等**：智能语音助手，集成在手机、音箱等设备中，具备语音交互、智能家居控制等功能。

这一阶段的智能机器人主要依赖于机器学习（如语音识别、自然语言理解）和大数据，能够理解用户的自然语言指令，并与互联网服务集成，实现更丰富的交互和自动化能力。虽然智能水平较早期有显著提升，但仍以“工具型助手”为主，缺乏自主规划和复杂推理能力。

![基于NLU的智能机器人](./assets/ai_agent/nlu.png)

### 阶段三：基于LLM的AI Agent

相比于阶段二，LLM（大语言模型）为智能机器人赋予了“灵魂”，带来了以下核心变革：

- **通用性与泛化能力**：LLM具备强大的知识迁移和泛化能力，不再局限于特定领域或任务，能够应对开放域的复杂对话和推理。
- **自主规划与推理**：LLM能够理解复杂指令，进行多步推理和自主任务拆解，具备一定的“思考”与“规划”能力。
- **上下文理解与记忆**：通过长上下文建模，LLM可以记住对话历史，实现更自然、连贯的人机交互。
- **知识整合与动态学习**：LLM在参数中蕴含了海量世界知识，并能通过检索、工具调用等方式动态补充新知识。
- **多模态能力**：新一代LLM支持文本、图像、语音等多模态输入输出，拓展了机器人的感知和表达能力。
- **Agent化架构**：LLM不仅作为“对话引擎”，更作为智能体的“决策大脑”，能够调用外部工具、API、插件，完成复杂任务编排。

![llm based systems](./assets/ai_agent/llm_based_ai_system.jpg)

基于LLM的智能机器人架构可以分为三类：
1. 对话机器人：ChatGPT等
2. Copilot：比较成熟的是各种辅助编码工具比如Github Copilot, CodeMate, Cursor, Claude Code
3. Agent：全智能系统，机器人从“工具型助手”进化为具备一定自主性、推理能力和复杂任务执行能力的“智能体”，成为AI发展的新范式。

## AI Agent的架构核心特性

![基于LLM的AI Agent](./assets/ai_agent/agent_overview.png)

- **自主性**：可以无需人工干预，自主的执行各种命令（也可以人工介入保持控制）；
- **记忆**： 借助LLM的长上下文或者外部的记忆系统，保留和存储个人信息实现个性化，同时可以处理信息，制定决策；
- **感知/交互**：可以使用工具，感知和处理来自环境的信息，比如访问互联网、知识库，执行代码或者调用API；
- **协作**：Agent可以和其他Agent或人类协作完成任务。

### 常见架构

![agent architecture](./assets/ai_agent/architecture.png)

## 如何构建基于LLM的AI Agent

![landscape](./assets/ai_agent/ai_agents_landscape.png)

### Code-Based

- Langchain/Langgraph
- CrewAI
- AutoGPT

### Low-Code/No-Code

- [Dify](https://dify.ai/)
- [Coze](https://www.coze.cn/studio)

![Coze](./assets/ai_agent/coze.png)


## Reference

[What is an AI Agent?](https://bytebytego.com/guides/what-is-an-ai-agent/)
