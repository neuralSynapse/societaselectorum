#!/usr/bin/env python3
from __future__ import annotations
import json
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
STORY=ROOT/'data/narrative/chronica_story_bible.json'
OUT=ROOT/'docs/canon/CHRONICA_HARUN_CANONE_NARRATIVO_v2_0_2026-09-07.md'


def render() -> str:
    s=json.loads(STORY.read_text(encoding='utf-8'))
    lines=[]
    lines += [
        '# CHRONICA HARUN · CÂNONE NARRATIVO v2.0',
        '',
        '**Status:** CANÔNICO PARA O JOGO  ',
        '**Data:** 2026-09-07  ',
        '**Autor real creditado:** Frater Horus Phosphorus  ',
        '**Regra de autoria:** Frater Harun é personagem canônico. Não é o autor real da obra.',
        '',
        '## Regência narrativa',
        '',
        'CHRONICA HARUN é uma prequela jogável da figura de Harun que mais tarde aparece em *Opus Lux Ferre*. A narrativa parte da cosmogonia, atravessa a linhagem da Marca e termina em Aleppo, c. 1585, no instante em que a formação de Harun deixa de ser apenas uma jornada pessoal e se torna capacidade de orientar sem fabricar dependência.',
        '',
        'O princípio dramático central é **VER · GOVERNAR · FAZER**. Cada parte da história precisa cumprir duas funções ao mesmo tempo: mover emocionalmente a história de Harun e ensinar uma gramática que retorne como decisão de gameplay.',
        '',
        '### Proveniência obrigatória',
        '',
        '- **FONTE (`source`)**: sustentado diretamente pela fonte governante usada no projeto.',
        '- **TRADIÇÃO (`tradition`)**: recepção ou corrente histórica distinta.',
        '- **INTERPRETAÇÃO (`interpretation`)**: leitura editorial/filosófica contemporânea.',
        '- **DRAMATIZAÇÃO ELECTORUM (`electorum_dramatization`)**: síntese ou ficção canônica do jogo.',
        '',
        'A luz luciferiana interna de Yaldabaoth, a descendência direta de Harun a partir da linhagem de Caim, a posição de Lilith antes de Eva no arco do jogo e o **GRIMORIUM ASCENSIONIS** são cânone diegético, mas jamais são apresentados como se fossem declarações literais de uma única fonte antiga.',
        '',
        '## Abertura cinematográfica',
        '',
        'Primeira exibição: aproximadamente **8m20s**. A narração é deliberadamente esparsa. A imagem mostra primeiro; a voz nomeia apenas o necessário. O Codex recebe a profundidade documental.',
        ''
    ]
    for scene in s['prologue']:
        lines += [f"### {scene['order']:02d} · {scene['title']}", '', f"**Frase-âncora:** {scene['anchor']}", '', f"**Gancho:** {scene['cinematic_hook']}", '', '**Narração final:**']
        lines += [f"> {x}" for x in scene['voiceover']]
        lines += ['', f"**Imagem de saída:** {scene['exit_image']}", '', f"**Função estratégica:** {scene['player_learning']}", '', f"**Proveniência:** `{scene['provenance']['primary_class']}`", '']
    lines += ['## Motivos recorrentes', '']
    for key,row in s['recurring_motifs'].items():
        lines += [f"### {key.replace('_',' ').upper()}", '', row['meaning'], '', '**Retornos:** ' + ' → '.join(row['appearances']), '']
    lines += ['## Jornada do Estudante · história integral de Harun', '', 'As quinze provas e a Câmara de Iniciação não são “fases temáticas” desconectadas. Cada uma destrói uma interpretação insuficiente de Harun, exige uma decisão sob custo e retorna mais tarde como competência ou cicatriz.', '']
    for stage in s['student_journey']:
        lines += [f"### {stage['order']:02d} · {stage['title']} · {stage['subtitle']}", '', f"**Imagem de abertura:** {stage['opening_image']}", '', f"**Conflito de Harun:** {stage['harun_conflict']}", '', f"**Pergunta dramática:** {stage['dramatic_question']}", '', f"**Aposta pessoal:** {stage['personal_stake']}", '', f"**Escolha sob pressão:** {stage['choice_under_pressure']}", '', f"**Terror:** {stage['horror_device']}", '', f"**Verdade do boss:** {stage['boss_revelation']}", '', f"**Sentido da recompensa:** {stage['reward_meaning']}", '', f"**Presságio:** {stage['foreshadow']}", '', '**Voz da etapa:**']
        lines += [f"> {x}" for x in stage['stage_voiceover']]
        lines += ['', '**Batidas dramáticas:**']
        for beat in stage['beats']:
            lines.append(f"- **{beat['id']} · {beat['function']}**: {beat['text']}")
        lines += ['', f"**Aprendizado estratégico:** {stage['strategic_lesson']}", '']
    ep=s['epilogue']
    lines += ['## Epílogo · A SEGUNDA SOMBRA', '', f"**Lugar:** {ep['location']}  ", f"**Data:** {ep['date_display']}  ", f"**Continuidade:** `{ep['continuity_target']}`", '', 'A última imagem cósmica reduz-se ao óleo de uma lamparina. Harun não termina a CHRONICA como alguém que recebeu todas as respostas. Termina como alguém capaz de suportar a pergunta sem entregá-la pronta ao próximo homem.', '', '**Narração final:**']
    lines += [f"> {x}" for x in ep['voiceover']]
    lines += ['', 'Um pavio está aceso. O segundo permanece apagado. Existem duas sombras no teto.', '', 'A palavra final é:', '', '# LUCIFER', '', 'Corte seco para preto.', '', '---', '', '**Cânone autoral:** Frater Horus Phosphorus.  ', '**Frater Harun é personagem desta obra.**', '']
    return '\n'.join(lines)


def main():
    OUT.parent.mkdir(parents=True,exist_ok=True)
    OUT.write_text(render(),encoding='utf-8')
    print(OUT)

if __name__=='__main__': main()
