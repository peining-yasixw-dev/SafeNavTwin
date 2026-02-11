using System;
using System.IO;
using UnityEngine;

public class ExperimentLogger : MonoBehaviour
{
    [Header("Experiment Metadata")]
    public string participantId = "P001";
    public string condition = "C1";
    public int trial = 1;

    [Header("Logging")]
    public bool logEveryFrame = false;   // 实验不要默认开，容易爆文件
    public float sampleHz = 20f;         // 20Hz 足够（0.05s一次）
    public string fileName = "raydata";

    private string filePath;
    private float nextT = 0f;

    void Awake()
    {
        string timestamp = DateTime.Now.ToString("yyyyMMdd_HHmmss");
        filePath = Path.Combine(Application.persistentDataPath, $"{fileName}_{participantId}_{timestamp}.csv");

        // 写表头
        File.WriteAllText(filePath,
            "unixTime,unityTime,participant,condition,trial,event,rayDistance,hitX,hitY,hitZ,agentX,agentY,agentZ\n");

        Debug.Log($"[LOGGER] Writing to: {filePath}");
    }

    public void LogSample(string evt, float dist, Vector3 hitPoint, Vector3 agentPos)
    {
        long unixMs = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds();
        string line =
            $"{unixMs},{Time.time:F4},{participantId},{condition},{trial},{evt},{dist:F4}," +
            $"{hitPoint.x:F4},{hitPoint.y:F4},{hitPoint.z:F4}," +
            $"{agentPos.x:F4},{agentPos.y:F4},{agentPos.z:F4}\n";

        File.AppendAllText(filePath, line);
    }

    void Update()
    {
        if (!logEveryFrame)
        {
            if (Time.time < nextT) return;
            nextT = Time.time + (1f / Mathf.Max(1f, sampleHz));
        }

        // 如果你想在这里做“持续采样”，之后我们把 ToF/Ray 脚本接进来
    }

    public string GetFilePath() => filePath;
}
