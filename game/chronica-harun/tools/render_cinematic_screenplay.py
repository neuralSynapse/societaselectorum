#!/usr/bin/env python3
from __future__ import annotations
import json
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
STORY=ROOT/'data/narrative/chronica_story_bible.json'
OUT=ROOT/'docs/canon/CHRONICA_HARUN_ROTEIRO_CINEMATOGRAFICO_v1_0_2026-09-07.md'


def render() -> str:
    s=json.loads(STORY.read_text(encoding='utf-8'))
    lines=[
      '# CHRONICA HARUN · ROTEIRO CINEMATOGRÁFICO v1.0','',
      '**Status:** CANÔNICO PARA PRODUÇÃO  ',
      '**Autor real:** Frater Horus Phosphorus  ',
      '**Função:** especificar plano, tempo, câmera, imagem, áudio, tensão, narração e transição da abertura e das decisões da Jornada.','',
      '## Princípio de direção','',
      'A ameaça aparece primeiro como **mudança de regra, som, ausência ou informação incompleta**. A criatura vem depois. Violência é curta; consequência permanece. Revelações usam match cuts entre motivos recorrentes para que a história pareça causal antes de ser explicada.','',
      'A primeira devolução de controle ao jogador ocorre diante da porta formada pelo **GRIMORIUM ASCENSIONIS**, com uma respiração além dela. O tutorial nasce dentro do suspense, não interrompe o suspense.',''
    ]
    for scene in s['prologue']:
        lines += [f"## {scene['order']:02d} · {scene['title']}",'',f"**Duração:** {scene['duration_seconds']}s  ",f"**Tensão-base:** {scene['tension']:.2f}  ",f"**Âncora:** {scene['anchor']}",'','### Voz']
        for v in scene['voiceover']: lines.append(f'> {v}')
        lines += ['','### Planos']
        for i,shot in enumerate(scene['shots'],1):
            lines += [f"#### Plano {i:02d} · `{shot['id']}`",'',f"- **Tempo:** {shot['duration_seconds']}s",f"- **Câmera:** {shot['camera']}",f"- **Imagem:** {shot['visual_event']}",f"- **Áudio:** {shot['audio_event']}",f"- **Transição:** `{shot['transition']}`",f"- **Tensão:** {shot['tension']:.2f}",f"- **Função dramática:** `{shot['dramatic_function']}`",'']
        lines += [f"**Imagem de saída:** {scene['exit_image']}",'',f"**Aprendizado do jogador:** {scene['player_learning']}",'','---','']
    lines += ['# Decisões estratégicas da Jornada','', 'Nenhuma escolha recebe selo de “correta”. O jogo informa preço e consequência narrativa; sistemas externos recebem apenas um `external_hook` estável para aplicar efeitos mecânicos sem contaminar o cânone.','']
    for st in s['student_journey']:
        c=st['choice_event']
        lines += [f"## {st['order']:02d} · {st['title']} · {st['subtitle']}",'',f"**Pergunta:** {c['prompt']}",'']
        for o in c['options']:
            lines += [f"### {o['label']}",'',f"- **Custo imediato:** {o['immediate_cost']}",f"- **Consequência narrativa:** {o['story_consequence']}",f"- **Hook mecânico:** `{o['external_hook']}`",'']
        lines += ['---','']
    ep=s['epilogue']
    lines += ['# Epílogo · A SEGUNDA SOMBRA','',f"**{ep['location']} · {ep['date_display']}**",'',*['> '+v for v in ep['voiceover']], '', '### Planos finais']
    for i,shot in enumerate(ep.get('shots',[]),1):
        lines += [f"#### Plano E{i:02d} · `{shot['id']}`",'',f"- **Tempo:** {shot['duration_seconds']}s",f"- **Câmera:** {shot['camera']}",f"- **Imagem:** {shot['visual_event']}",f"- **Áudio:** {shot['audio_event']}",f"- **Transição:** `{shot['transition']}`",f"- **Tensão:** {shot['tension']:.2f}",'']
    lines += ['**Última palavra:**', '', '# LUCIFER', '', 'Corte seco para preto.','']
    return '\n'.join(lines)


def main():
    OUT.parent.mkdir(parents=True,exist_ok=True)
    OUT.write_text(render(),encoding='utf-8')
    print(OUT)

if __name__=='__main__': main()
