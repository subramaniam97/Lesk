# Leaps and bounds? Let's see!
import string
import xml.etree.ElementTree as ET
from nltk.corpus import stopwords
from string import punctuation
from nltk import word_tokenize, pos_tag
from nltk.corpus import wordnet as wn
from utils import lemmatize, lemmatize_sentence
from collections import defaultdict
from utils import lemmatize, porter, lemmatize_sentence, synset_properties

maxiScore = 0
bestCandidate = []

def getSynsets(word, posTag):

    synsets_signatures = {}
    for ss in wn.synsets(word):
        gloss = []
        try:
            if posTag and str(ss.pos()) != posTag:
                continue
        except:
            if posTag and str(ss.pos) != posTag:
                continue

        gloss.append(synset_properties(ss, 'definition'))

        if posTag == wn.NOUN:
            ss_hyponyms = synset_properties(ss, 'hyponyms')
            ss_hypernyms = synset_properties(ss, 'hypernyms')
            ss_meronyms = synset_properties(ss, 'member_meronyms')
            ss_meronyms += synset_properties(ss, 'part_meronyms')
            ss_meronyms += synset_properties(ss, 'substance_meronyms')
            ss_holonyms = synset_properties(ss, 'member_holonyms')
            ss_holonyms += synset_properties(ss, 'part_holonyms')
            ss_holonyms += synset_properties(ss, 'substance_holonyms')
            gloss.append(" ".join(list([i.definition() for i in ss_hyponyms])))
            gloss.append(" ".join(list([i.definition() for i in ss_hypernyms])))
            gloss.append(" ".join(list([i.definition() for i in ss_meronyms])))
            gloss.append(" ".join(list([i.definition() for i in ss_holonyms])))


        elif posTag == wn.VERB or posTag == wn.ADV:
            ss_hypernyms = synset_properties(ss, 'hypernyms')
            ss_hyponyms = synset_properties(ss, 'hyponyms')
            gloss.append(" ".join(list([i.definition() for i in ss_hyponyms])))
            gloss.append(" ".join(list([i.definition() for i in ss_hypernyms])))

        elif posTag == wn.ADJ:
            ss_attributes = synset_properties(ss, 'attributes')
            gloss.append(" ".join(list([i.definition() for i in ss_attributes])))

        else:
            ss_hyponyms = synset_properties(ss, 'hyponyms')
            ss_hypernyms = synset_properties(ss, 'hypernyms')
            ss_meronyms = synset_properties(ss, 'member_meronyms')
            ss_meronyms += synset_properties(ss, 'part_meronyms')
            ss_meronyms += synset_properties(ss, 'substance_meronyms')
            ss_holonyms = synset_properties(ss, 'member_holonyms')
            ss_holonyms += synset_properties(ss, 'part_holonyms')
            ss_holonyms += synset_properties(ss, 'substance_holonyms')
            ss_attributes = synset_properties(ss, 'attributes')
            gloss.append(" ".join(list([i.definition() for i in ss_hyponyms])))
            gloss.append(" ".join(list([i.definition() for i in ss_hypernyms])))
            gloss.append(" ".join(list([i.definition() for i in ss_meronyms])))
            gloss.append(" ".join(list([i.definition() for i in ss_holonyms])))
            gloss.append(" ".join(list([i.definition() for i in ss_attributes])))

        gloss = [x for x in gloss if x]
        synsets_signatures[ss] = gloss

    if len(synsets_signatures) == 0:
        return None
    return synsets_signatures

def checkNonContent(s):

    ok = 0
    sentence = " ".join(s)
    for word, pos in pos_tag(word_tokenize(sentence)):
        if checkTag(pos) == 1:
            ok = 1
            break
    return ok

def checkTag(penntag):
    morphDict = {'NN':wn.NOUN, 'JJ':wn.ADJ, 'NNS':wn.NOUN, 'JJS':wn.ADJ, 'JJR':wn.ADJ, 'RBR':wn.ADV,
                  'VB':wn.VERB, 'RB':wn.ADV, 'RBS':wn.ADV, 'VBD':wn.VERB, 'VBG':wn.VERB, 'VBN':wn.VERB}
    if penntag in morphDict:
        return 1
    return 0

def computeOverlap(S, T):

    m = len(S)
    n = len(T)
    score = 0
    counter = [[0] * (n + 1) for x in range(m + 1)]
    longest = 0
    stS = -1
    enS = -1
    stT = -1
    enT = -1
    for i in range(m):
        for j in range(n):
            if S[i] == T[j]:
                c = counter[i][j] + 1
                counter[i + 1][j + 1] = c
                if c > longest:
                    longest = c
                    stS = i - c + 1
                    enS = i
                    stT = j - c + 1
                    enT = j

    if longest <= 1:
        return 0
    if stS == -1:
        return 0
    Sd1 = []
    Sd2 = []
    for i in range(stS):
        Sd1.append(S[i])
    for i in range(enS + 1, m):
        Sd2.append(S[i])

    Td1 = []
    Td2 = []
    for i in range(stT):
        Td1.append(T[i])
    for i in range(enT + 1, n):
        Td2.append(T[i])


    if checkNonContent(S[stS : enS + 1]) == 1:
        score = (longest * longest)
    else:
        score = 0

    return score + computeOverlap(Sd1, Td1) + computeOverlap(Sd2, Td2)

def compareGlossesList(a, b):

    score = 0
    n = len(a)
    m = len(b)
    for i in range(n):
        for j in range(m):
            score += computeOverlap(a[i].split(), b[j].split())
    return score


def computeScore(candidate):

    score = 0
    n = len(candidate)
    for i in range(n):
        for j in range(i + 1, n):
            score += compareGlossesList(candidate[i], candidate[j])
    return score


def candHelper(glossMat, synMat, n, m, glossCandidate, synCandidate, R, C):

    global maxiScore
    global bestCandidate
    glossCandidate[n] = glossMat[n][m]
    synCandidate[n] = synMat[n][m]
    if n == R - 1:
        score = computeScore(glossCandidate)
        if score > maxiScore:
            maxiScore = score
            bestCandidate = synCandidate
        return

    for i in range(C):
        if glossMat[n + 1][i] != None:
            candHelper(glossMat, synMat, n + 1, i, glossCandidate, synCandidate, R, C)

def candComb(glossMat, synMat):

    R = len(glossMat)
    C = len(glossMat[0])
    glossCandidate = [""] * R
    synCandidate = [""] * R
    #print('R: ', R)
    #print('C: ', C)
    for i in range(C):
        if glossMat[0][i] != None:
            candHelper(glossMat, synMat, 0, i, glossCandidate, synCandidate, R, C)

def adaptedLesk(contextSentence, posTarget, morphy_poss):

    global maxiScore
    global bestCandidate
    if not wn.synsets(contextSentence[posTarget]):
        return None

    glossMat = []
    synMat = []
    posInSynMat = -1
    maxi = 0
    ctr = 0

    for i in range(len(contextSentence)):
        arr = getSynsets(contextSentence[i], morphy_poss[i])
        if not arr == None:
            lst = []
            for x in arr.values():
                lst.append(x)
            glossMat.append(lst)
            lst = []
            for x in arr.keys():
                lst.append(x)
            synMat.append(lst)
            maxi = max(maxi, len(arr))
            if i == posTarget:
                posInSynMat = ctr
            else:
                ctr += 1

    for i in glossMat:
        while not len(i) == maxi:
            i.append(None)

    maxiScore = 0
    bestCandidate = []

    candComb(glossMat, synMat)

    #print('Maximum Score: ', maxiScore)
    #print('Best Candidate: ', bestCandidate)
    #print('Position: ', posInSynMat)

    return bestCandidate[posInSynMat]


def disambiguateWithHead(sentence, posTarget, halfWindowLength = 5):

    stopwords1 = stopwords.words('english') + list(punctuation)
    tagged_sentence = []
    reqWord = word_tokenize(sentence)[posTarget]

    #print('Required Word: ', reqWord)

    surface_words, lemmas, morphy_poss = lemmatize_sentence(sentence, keepWordPOS=True)

    contextSentence = []
    poss = []
    lctr = 0
    rctr = 0
    tctr = 0
    lp = posTarget - 1
    rp = posTarget + 1
    n = len(lemmas)

    while lp >= 0:
        if not wn.synsets(lemmas[lp]):
            lp -= 1
            continue
        contextSentence.append(lemmas[lp])
        poss.append(morphy_poss[lp])
        lp -= 1
        lctr += 1
        if lctr == halfWindowLength:
            break

    contextSentence.append(lemmas[posTarget])
    poss.append(morphy_poss[posTarget])
    positionOfReqWord = len(contextSentence) - 1

    while rp < n:
        if not wn.synsets(lemmas[rp]):
            rp += 1
            continue
        contextSentence.append(lemmas[rp])
        poss.append(morphy_poss[rp])
        rp += 1
        rctr += 1
        if rctr == halfWindowLength:
            break

    tctr = rctr + lctr

    while lp >= 0:
        if tctr == halfWindowLength + halfWindowLength:
            break
        if not wn.synsets(lemmas[lp]):
            lp -= 1
            continue
        contextSentence.append(lemmas[lp])
        poss.append(morphy_poss[lp])
        lp -= 1
        tctr += 1


    while rp < n:
        if tctr == halfWindowLength + halfWindowLength:
            break
        if not wn.synsets(lemmas[rp]):
            rp += 1
            continue
        contextSentence.append(lemmas[rp])
        poss.append(morphy_poss[rp])
        rp += 1
        tctr += 1

    #print('Context Sentence: ', contextSentence)

    if contextSentence[positionOfReqWord] not in stopwords1:
        try:
            synset = adaptedLesk(contextSentence, positionOfReqWord, poss)
        except:
            synset = '#NOT_IN_WN#'
    else:
        synset = '#STOPWORD/PUNCTUATION#'

    tagged_sentence.append((reqWord, synset))

    tagged_sentence = [(word, None) if str(tag).startswith('#')
                       else (word, tag) for word, tag in tagged_sentence]
    return tagged_sentence


if __name__ == "__main__":

    keypath = '/home/subbu/Desktop/MP/pylesk/senseval/Sval2.keys/Senseval2.key'

    keylist = []
    num = 0
    denom = 0

    keysDict = defaultdict(list)

    with open(keypath) as kp:
        line = kp.readline()
        while line:
            tlist = line.split()
            instanceID = tlist[1]
            tlist = tlist[2:]
            keysDict[instanceID] = tlist
            line = kp.readline()

    tree = ET.parse("/home/subbu/Desktop/MP/pylesk/senseval/Sval2.xml/dataWithoutHead.xml")
    tree1 = ET.parse("/home/subbu/Desktop/MP/pylesk/senseval/Sval2.xml/data.xml")
    root = tree.getroot()
    root1 = tree1.getroot()

    ctr = 0
    cnt = 0
    for lexltIndex in range(len(root)):
        for inst in range(len(root[lexltIndex])):
            try:
                line = root[lexltIndex][inst][0].text
                instanceID = root[lexltIndex][inst].attrib["id"]
                posTarget = len(word_tokenize(root1[lexltIndex][inst][0].text))
                #print(instanceID, word_tokenize(root[lexltIndex][inst][0].text)[posTarget])
                #print(line, posTarget)
                synset = disambiguateWithHead(line, posTarget, halfWindowLength = 1)
                #print('Selected: ', synset)
                done = 0
                for i in range(len(synset[0][1].lemmas())):
                    if done == 1:
                        break
                    s = synset[0][1].lemmas()[i].key()
                    #print(instanceID, s)
                    #print(synset)
                    #print(denom + 1, ": ", line.split()[posTarget],  s)
                    for x in keysDict[instanceID]:
                        if x == s:
                            #print(instanceID, x, s)
                            num += 1
                            done = 1
                            break
                denom += 1
                cnt += 1
            except:
                ctr += 1
                cnt += 1
                #print("error ", ctr)
                pass

            print("Line: ", cnt, "Accuracy: ", num / denom)

print("Matches: ", num)
print("Errors: ", ctr)
