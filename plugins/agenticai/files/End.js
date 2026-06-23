// Copyright (C) 2024-2025 Intel Corporation
// SPDX-License-Identifier: Apache-2.0
//
// This file provides the missing 'endAgentflow' node component for Flowise v3.0.x.
// The End node type is referenced by agentflow templates (e.g. software-team.json)
// but is absent from the flowise-components package shipped in Flowise v3.0.x.
// It is injected at runtime via a Kubernetes ConfigMap volume mount.
//
// Behaviour: receives the final LLM output via the 'endInput' variable, streams
// it back to the SSE client when this is the last node, and terminates the flow.

"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
class End_Agentflow {
    constructor() {
        this.label = 'End';
        this.name = 'endAgentflow';
        this.version = 1.0;
        this.type = 'End';
        this.category = 'Agent Flows';
        this.description = 'End point of the agentflow';
        this.baseClasses = [this.type];
        this.color = '#F06D68';
        this.hideOutput = true;
        this.inputs = [
            {
                label: 'End Input',
                name: 'endInput',
                type: 'string',
                description: 'The final response to be sent to the user',
                acceptVariable: true,
                optional: true
            }
        ];
    }
    async run(nodeData, _, options) {
        const endInput = nodeData.inputs?.endInput ?? '';
        const state = options.agentflowRuntime?.state;
        const chatId = options.chatId;
        const isLastNode = options.isLastNode;
        const isStreamable = isLastNode && options.sseStreamer !== undefined;
        if (isStreamable && endInput) {
            const sseStreamer = options.sseStreamer;
            sseStreamer.streamTokenEvent(chatId, endInput);
        }
        const returnOutput = {
            id: nodeData.id,
            name: this.name,
            input: { endInput },
            output: {
                content: endInput
            },
            state
        };
        return returnOutput;
    }
}
module.exports = { nodeClass: End_Agentflow };
